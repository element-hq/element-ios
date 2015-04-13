/*
 Copyright 2014 OpenMarket Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MatrixSDKHandler.h"
#import "AppDelegate.h"
#import "AppSettings.h"

#import "MXFileStore.h"
#import "MXTools.h"

#import "AFNetworkReachabilityManager.h"

#import <AudioToolbox/AudioToolbox.h>

static MatrixSDKHandler *sharedHandler = nil;

@interface MatrixSDKHandler () {
    // We will notify user only once on session failure
    BOOL notifyOpenSessionFailure;
    NSTimer* initialServerSyncTimer;
    
    // Handle user's settings change
    id userUpdateListener;
    // Handle events notification
    id notificationCenterListener;
    // Reachability observer
    id reachabilityObserver;

    // Used for logging application start up
    NSDate *openSessionStartDate;
    
    MXKEventFormatter *eventFormatter;
}

@property (strong, nonatomic) MXFileStore *mxFileStore;
@property (nonatomic,readwrite) MatrixSDKHandlerStatus status;
@property (nonatomic,readwrite) BOOL isActivityInProgress;
@property (strong, nonatomic) MXKAlert *mxNotification;
@property (nonatomic) UIBackgroundTaskIdentifier bgTask;

@property (strong, nonatomic) NSMutableDictionary *partialTextMsgByRoomId;

// When the user cancels an inApp notification
// assume that any messagge room will be ignored
// until the next launch / debackground
@property (nonatomic,readwrite) NSMutableArray* unnotifiedRooms;
@end

@implementation MatrixSDKHandler

+ (MatrixSDKHandler *)sharedHandler {
    @synchronized(self) {
        if(sharedHandler == nil)
        {
            sharedHandler = [[super allocWithZone:NULL] init];
        }
    }
    return sharedHandler;
}

#pragma  mark - 

-(MatrixSDKHandler *)init {
    if (self = [super init]) {
        self.status = (self.accessToken != nil) ? MatrixSDKHandlerStatusLogged : MatrixSDKHandlerStatusLoggedOut;
        _userPresence = MXPresenceUnknown;
        notifyOpenSessionFailure = YES;
        
        NSString *label = [NSString stringWithFormat:@"com.matrix.%@.MatrixSDKHandler", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];
        _processingQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        
        // Read potential homeserver url in shared defaults object
        if (self.homeServerURL) {
            self.mxRestClient = [[MXRestClient alloc] initWithHomeServer:self.homeServerURL];
            if (self.identityServerURL) {
                [self.mxRestClient setIdentityServer:self.identityServerURL];
            }
            
            if (self.accessToken) {
                [self openSession];
            }
        }
        
        _unnotifiedRooms = [[NSMutableArray alloc] init];
        _partialTextMsgByRoomId = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:reachabilityObserver];
    reachabilityObserver = nil;
    
    [initialServerSyncTimer invalidate];
    initialServerSyncTimer = nil;
    
    _processingQueue = nil;
    
    _unnotifiedRooms = nil;
    
    _partialTextMsgByRoomId = nil;
    
    [self closeSession];
    self.mxSession = nil;
    
    if (self.mxNotification) {
        [self.mxNotification dismiss:NO];
        self.mxNotification = nil;
    }
}

- (void)openSession {
    MXCredentials *credentials = [[MXCredentials alloc] initWithHomeServer:self.homeServerURL
                                                                    userId:self.userId
                                                               accessToken:self.accessToken];

    openSessionStartDate = [NSDate date];
    self.mxRestClient = [[MXRestClient alloc] initWithCredentials:credentials];
    if (self.mxRestClient) {
        // Set identity server (if any)
        if (self.identityServerURL) {
            [self.mxRestClient setIdentityServer:self.identityServerURL];
        }
        
        // Use MXFileStore as MXStore to permanently store events
        _mxFileStore = [[MXFileStore alloc] init];

        self.mxSession = [[MXSession alloc] initWithMatrixRestClient:self.mxRestClient];
        
        // Build MXEvent -> NSString formatter
        eventFormatter = [[MXKEventFormatter alloc] initWithMatrixSession:self.mxSession];
        eventFormatter.isForSubtitle = YES;
        
        __weak typeof(self) weakSelf = self;
        [self.mxSession setStore:_mxFileStore success:^{
            typeof(self) self = weakSelf;
            self.status = MatrixSDKHandlerStatusStoreDataReady;
            // Check here whether the app user wants to display all the events
            if ([[AppSettings sharedSettings] displayAllEvents]) {
                // Use a filter to retrieve all the events (except kMXEventTypeStringPresence which are not related to a specific room)
                self.eventsFilterForMessages = @[
                                                 kMXEventTypeStringRoomName,
                                                 kMXEventTypeStringRoomTopic,
                                                 kMXEventTypeStringRoomMember,
                                                 kMXEventTypeStringRoomCreate,
                                                 kMXEventTypeStringRoomJoinRules,
                                                 kMXEventTypeStringRoomPowerLevels,
                                                 kMXEventTypeStringRoomAliases,
                                                 kMXEventTypeStringRoomMessage,
                                                 kMXEventTypeStringRoomMessageFeedback,
                                                 kMXEventTypeStringRoomRedaction
                                                 ];
            }
            else {
                // Display only a subset of events
                self.eventsFilterForMessages = @[
                                                 kMXEventTypeStringRoomName,
                                                 kMXEventTypeStringRoomTopic,
                                                 kMXEventTypeStringRoomMember,
                                                 kMXEventTypeStringRoomMessage
                                                 ];
            }
            
            // Complete session registration by launching live stream
            [self launchInitialServerSync];
        } failure:^(NSError *error) {
            // This cannot happen. Loading of MXFileStore cannot fail.
            typeof(self) self = weakSelf;
            self.mxSession = nil;
        }];
    }
}

- (void)launchInitialServerSync {
    // Complete the session registration when store data is ready.
    
    // Cancel potential reachability observer and pending action
    [[NSNotificationCenter defaultCenter] removeObserver:reachabilityObserver];
    reachabilityObserver = nil;
    [initialServerSyncTimer invalidate];
    initialServerSyncTimer = nil;
    
    // Sanity check
    if (self.status != MatrixSDKHandlerStatusStoreDataReady) {
        NSLog(@"[MatrixSDKHandler] Initial server sync is applicable only when store data is ready to complete session initialisation");
        return;
    }
    
    // Launch mxSession
    self.status = MatrixSDKHandlerStatusInitialServerSyncInProgress;
    [self.mxSession start:^{
        NSLog(@"[MatrixSDKHandler] The app is ready. Matrix SDK session has been started in %0.fms.", [[NSDate date] timeIntervalSinceDate:openSessionStartDate] * 1000);
        self.status = MatrixSDKHandlerStatusServerSyncDone;
        [self setUserPresence:MXPresenceOnline andStatusMessage:nil completion:nil];
        
        // Register listener to update user's information
        userUpdateListener = [self.mxSession.myUser listenToUserUpdate:^(MXEvent *event) {
            // Consider only events related to user's presence
            if (event.eventType == MXEventTypePresence) {
                MXPresence presence = [MXTools presence:event.content[@"presence"]];
                if (self.userPresence != presence) {
                    // Handle user presence on multiple devices (keep the more pertinent)
                    if (self.userPresence == MXPresenceOnline) {
                        if (presence == MXPresenceUnavailable || presence == MXPresenceOffline) {
                            // Force the local presence to overwrite the user presence on server side
                            [self setUserPresence:_userPresence andStatusMessage:nil completion:nil];
                            return;
                        }
                    } else if (self.userPresence == MXPresenceUnavailable) {
                        if (presence == MXPresenceOffline) {
                            // Force the local presence to overwrite the user presence on server side
                            [self setUserPresence:_userPresence andStatusMessage:nil completion:nil];
                            return;
                        }
                    }
                    self.userPresence = presence;
                }
            }
        }];
        
        // Check whether the app user wants notifications on new events
        if ([[AppSettings sharedSettings] enableInAppNotifications]) {
            [self enableInAppNotifications:YES];
        }
    } failure:^(NSError *error) {
        NSLog(@"[MatrixSDKHandler] Initial Sync failed: %@", error);
        if (notifyOpenSessionFailure) {
            //Alert user only once
            notifyOpenSessionFailure = NO;
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }
        
        // Return in previous state
        self.status = MatrixSDKHandlerStatusStoreDataReady;
        
        // Check network reachability
        if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorNotConnectedToInternet) {
            // Add observer to launch a new attempt according to reachability.
            reachabilityObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AFNetworkingReachabilityDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                NSNumber *statusItem = note.userInfo[AFNetworkingReachabilityNotificationStatusItem];
                if (statusItem) {
                    AFNetworkReachabilityStatus reachabilityStatus = statusItem.integerValue;
                    if (reachabilityStatus == AFNetworkReachabilityStatusReachableViaWiFi || reachabilityStatus == AFNetworkReachabilityStatusReachableViaWWAN) {
                        // New attempt
                        [self launchInitialServerSync];
                    }
                }
            }];
        } else {
            // Postpone a new attempt in 10 sec
            initialServerSyncTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(launchInitialServerSync) userInfo:self repeats:NO];
        }
    }];
}

- (void)closeSession {
    self.status = (self.accessToken != nil) ? MatrixSDKHandlerStatusLogged : MatrixSDKHandlerStatusLoggedOut;
    
    if (notificationCenterListener) {
        [self.mxSession.notificationCenter removeListener:notificationCenterListener];
        notificationCenterListener = nil;
    }
    if (userUpdateListener) {
        [self.mxSession.myUser removeListener:userUpdateListener];
        userUpdateListener = nil;
    }
    
    [self.mxSession close];
    self.mxSession = nil;
    
    [self.mxRestClient close];
    
    if (self.homeServerURL) {
        self.mxRestClient = [[MXRestClient alloc] initWithHomeServer:self.homeServerURL];
        if (self.identityServerURL) {
            [self.mxRestClient setIdentityServer:self.identityServerURL];
        }
    } else {
        self.mxRestClient = nil;
    }
    
    notifyOpenSessionFailure = YES;
}

#pragma mark -

- (void)pauseInBackgroundTask {
    // Hide potential notification
    if (self.mxNotification) {
        [self.mxNotification dismiss:NO];
        self.mxNotification = nil;
    }
    
    _unnotifiedRooms = [[NSMutableArray alloc] init];
    
    if (self.mxSession && self.status == MatrixSDKHandlerStatusServerSyncDone) {
        _bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
            _bgTask = UIBackgroundTaskInvalid;
            
            NSLog(@"[MatrixSDKHandler] pauseInBackgroundTask : %08lX expired", (unsigned long)_bgTask);
        }];
        
        NSLog(@"[MatrixSDKHandler] pauseInBackgroundTask : %08lX starts", (unsigned long)_bgTask);
        // Pause SDK
        [self.mxSession pause];
        self.status = MatrixSDKHandlerStatusPaused;
        // Update user presence
        __weak typeof(self) weakSelf = self;
        [self setUserPresence:MXPresenceUnavailable andStatusMessage:nil completion:^{
            NSLog(@"[MatrixSDKHandler] pauseInBackgroundTask : %08lX ends", (unsigned long)weakSelf.bgTask);
            [[UIApplication sharedApplication] endBackgroundTask:weakSelf.bgTask];
            weakSelf.bgTask = UIBackgroundTaskInvalid;
            NSLog(@"[MatrixSDKHandler] >>>>> background pause task finished");
        }];
    } else {
        // Cancel pending actions
        [[NSNotificationCenter defaultCenter] removeObserver:reachabilityObserver];
        reachabilityObserver = nil;
        [initialServerSyncTimer invalidate];
        initialServerSyncTimer = nil;
    }
}

- (void)resume {
    if (self.mxSession) {
        if (self.status == MatrixSDKHandlerStatusPaused) {
            // Resume SDK and update user presence
            [self.mxSession resume:^{
                [self setUserPresence:MXPresenceOnline andStatusMessage:nil completion:nil];
                self.status = MatrixSDKHandlerStatusServerSyncDone;
            }];
        } else if (self.status == MatrixSDKHandlerStatusStoreDataReady) {
            // The session initialisation was uncompleted, we try to complete it here.
            [self launchInitialServerSync];
        }
        
        if (_bgTask) {
            // Cancel background task
            [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
            _bgTask = UIBackgroundTaskInvalid;
            NSLog(@"[MatrixSDKHandler] pauseInBackgroundTask : %08lX cancelled", (unsigned long)_bgTask);
        }
    }
}

- (void)logout {
    NSLog(@"[MatrixSDKHandler] logout");
    
    //[self setUserPresence:MXPresenceOffline andStatusMessage:nil completion:nil];
    
    // Reset access token (mxSession is closed by setter)
    self.accessToken = nil;
    self.userId = nil;
    self.homeServer = nil;
    
    _unnotifiedRooms = [[NSMutableArray alloc] init];
    _partialTextMsgByRoomId = [[NSMutableDictionary alloc] init];
    // Keep userLogin, homeServerUrl
}

- (void)reload:(BOOL)clearCache {
    if (self.mxSession) {
        [self closeSession];
        notifyOpenSessionFailure = NO;
        
        // Force back to Recents list if room details is displayed (Room details are not available until the end of initial sync)
        [[AppDelegate theDelegate].masterTabBarController popRoomViewControllerAnimated:NO];
        
        [[MXKRoomDataSourceManager sharedManagerForMatrixSession:self.mxSession] reset];
        
        if (clearCache) {
            // clear the media cache
            [MXKMediaManager clearCache];
            
            [_mxFileStore deleteAllData];
        }
        
        if (self.accessToken) {
            [self openSession];
        }
    }
}

- (void)enableInAppNotifications:(BOOL)isEnabled {
    if (isEnabled) {
        // Register on notification center
        notificationCenterListener = [self.mxSession.notificationCenter listenToNotifications:^(MXEvent *event, MXRoomState *roomState, MXPushRule *rule) {
            // Apply event filter
            if ([self.eventsFilterForMessages indexOfObject:event.type] == NSNotFound) {
                // Ignore
                return;
            }
            
            // Check conditions to display this notification
            if (![[AppDelegate theDelegate].masterTabBarController.visibleRoomId isEqualToString:event.roomId]
                && ![[AppDelegate theDelegate].masterTabBarController isPresentingMediaPicker]
                && ([self.unnotifiedRooms indexOfObject:event.roomId] == NSNotFound)) {
                
                MXKEventFormatterError error;
                NSString* messageText = [eventFormatter stringFromEvent:event withRoomState:roomState error:&error];
                if (messageText.length && (error != MXKEventFormatterErrorNone)) {
                    
                    // Removing existing notification (if any)
                    if (self.mxNotification) {
                        [self.mxNotification dismiss:NO];
                    }
                    
                    // Check whether tweak is required
                    for (MXPushRuleAction *ruleAction in rule.actions) {
                        if (ruleAction.actionType == MXPushRuleActionTypeSetTweak) {
                            if ([[ruleAction.parameters valueForKey:@"set_tweak"] isEqualToString:@"sound"]) {
                                // Play system sound (VoicemailReceived)
                                AudioServicesPlaySystemSound (1002);
                            }
                        }
                    }
                    
                    __weak typeof(self) weakSelf = self;
                    self.mxNotification = [[MXKAlert alloc] initWithTitle:roomState.displayname
                                                                  message:messageText
                                                                    style:MXKAlertStyleAlert];
                    self.mxNotification.cancelButtonIndex = [self.mxNotification addActionWithTitle:@"Cancel"
                                                                                              style:MXKAlertActionStyleDefault
                                                                                            handler:^(MXKAlert *alert) {
                                                                                                weakSelf.mxNotification = nil;
                                                                                                [weakSelf.unnotifiedRooms addObject:event.roomId];
                                                                                            }];
                    [self.mxNotification addActionWithTitle:@"View"
                                                      style:MXKAlertActionStyleDefault
                                                    handler:^(MXKAlert *alert) {
                                                        weakSelf.mxNotification = nil;
                                                        // Show the room
                                                        [[AppDelegate theDelegate].masterTabBarController showRoom:event.roomId];
                                                    }];
                    
                    [self.mxNotification showInViewController:[[AppDelegate theDelegate].masterTabBarController selectedViewController]];
                }
            }
        }];
    } else {
        if (notificationCenterListener) {
            [self.mxSession.notificationCenter removeListener:notificationCenterListener];
            notificationCenterListener = nil;
        }
        if (self.mxNotification) {
            [self.mxNotification dismiss:NO];
            self.mxNotification = nil;
        }
    }
}

#pragma mark - Properties

- (void)setStatus:(MatrixSDKHandlerStatus)status {
    // Remove potential reachability observer
    if (reachabilityObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:reachabilityObserver];
        reachabilityObserver = nil;
    }
    
    // Update activity flag
    switch (status) {
        case MatrixSDKHandlerStatusLoggedOut:
        case MatrixSDKHandlerStatusStoreDataReady:
        case MatrixSDKHandlerStatusServerSyncDone: {
            self.isActivityInProgress = NO;
            break;
        }
        case MatrixSDKHandlerStatusLogged:
        case MatrixSDKHandlerStatusInitialServerSyncInProgress: {
            self.isActivityInProgress = YES;
            break;
        }
        case MatrixSDKHandlerStatusPaused: {
            // Here the app is resuming, the activity is in progress except if the network is unreachable
            AFNetworkReachabilityStatus reachabilityStatus = [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
            self.isActivityInProgress = (reachabilityStatus == AFNetworkReachabilityStatusReachableViaWiFi || reachabilityStatus ==AFNetworkReachabilityStatusReachableViaWWAN);
            
            // Add observer to update handler activity according to reachability.
            reachabilityObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AFNetworkingReachabilityDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                NSNumber *statusItem = note.userInfo[AFNetworkingReachabilityNotificationStatusItem];
                if (statusItem) {
                    AFNetworkReachabilityStatus reachabilityStatus = statusItem.integerValue;
                    self.isActivityInProgress = (reachabilityStatus == AFNetworkReachabilityStatusReachableViaWiFi || reachabilityStatus ==AFNetworkReachabilityStatusReachableViaWWAN);
                }
            }];
            break;
        }
    }
    
    // Report status
    _status = status;
    NSLog(@"[MatrixSDKHandler] Updated status: %zd", status);
}

#pragma mark User's profile

- (NSString *)homeServerURL {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"homeserverurl"];
}

- (void)setHomeServerURL:(NSString *)inHomeServerURL {
    if (inHomeServerURL.length) {
        [[NSUserDefaults standardUserDefaults] setObject:inHomeServerURL forKey:@"homeserverurl"];
        self.mxRestClient = [[MXRestClient alloc] initWithHomeServer:inHomeServerURL];
        // Set identity server (if any)
        if (self.identityServerURL) {
            [self.mxRestClient setIdentityServer:self.identityServerURL];
        }
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"homeserverurl"];
        // Reinitialize matrix handler
        [self logout];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)homeServer {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"homeserver"];
}

- (void)setHomeServer:(NSString *)inHomeserver {
    if (inHomeserver.length) {
        [[NSUserDefaults standardUserDefaults] setObject:inHomeserver forKey:@"homeserver"];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"homeserver"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)userLogin {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"userlogin"];
}

- (void)setUserLogin:(NSString *)inUserLogin {
    if (inUserLogin.length) {
        [[NSUserDefaults standardUserDefaults] setObject:inUserLogin forKey:@"userlogin"];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"userlogin"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)userId {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"userid"];
}

- (void)setUserId:(NSString *)inUserId {
    if (inUserId.length) {
        [[NSUserDefaults standardUserDefaults] setObject:inUserId forKey:@"userid"];
        
        // Deduce local userid
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"localuserid"];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"@(.*):\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
        NSTextCheckingResult *match = [regex firstMatchInString:inUserId options:0 range:NSMakeRange(0, [inUserId length])];
        if (match.numberOfRanges == 2) {
            NSString* localId = [inUserId substringWithRange:[match rangeAtIndex:1]];
            if (localId) {
                [[NSUserDefaults standardUserDefaults] setObject:localId forKey:@"localuserid"];
            }
        }
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"userid"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"localuserid"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)localPartFromUserId {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"localuserid"];
}

- (NSString *)accessToken {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"accesstoken"];
}

- (void)setAccessToken:(NSString *)inAccessToken {
    if (inAccessToken.length) {
        [[NSUserDefaults standardUserDefaults] setObject:inAccessToken forKey:@"accesstoken"];
        [[AppDelegate theDelegate] registerUserNotificationSettings];
        self.status = MatrixSDKHandlerStatusLogged;
        [self openSession];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"accesstoken"];
        [self closeSession];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)identityServerURL {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"identityserverurl"];
}

- (void)setIdentityServerURL:(NSString *)inIdentityServerURL {
    if (inIdentityServerURL.length) {
        [[NSUserDefaults standardUserDefaults] setObject:inIdentityServerURL forKey:@"identityserverurl"];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"identityserverurl"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Update the current restClient
    if (self.mxRestClient) {
        [self.mxRestClient setIdentityServer:self.identityServerURL];
    }
}

#pragma mark - Matrix user's settings

- (void)setUserPresence:(MXPresence)userPresence andStatusMessage:(NSString *)statusMessage completion:(void (^)(void))completion {
    self.userPresence = userPresence;
    // Update user presence on server side
    [self.mxSession.myUser setPresence:userPresence andStatusMessage:statusMessage success:^{
        NSLog(@"[MatrixSDKHandler] Set user presence (%lu) succeeded", (unsigned long)userPresence);
        if (completion) {
            completion();
        }
    } failure:^(NSError *error) {
        NSLog(@"[MatrixSDKHandler] Set user presence (%lu) failed: %@", (unsigned long)userPresence, error);
    }];
}

#pragma mark - Room handling

// return a MatrixIDs list of 1:1 room members
- (NSArray*)oneToOneRoomMemberIDs {
    
    NSMutableArray* matrixIDs = [[NSMutableArray alloc] init];
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    
     if (mxHandler.mxSession) {
         NSArray *recentEvents = [NSMutableArray arrayWithArray:[mxHandler.mxSession recentsWithTypeIn:mxHandler.eventsFilterForMessages]];
         
         for (MXEvent *mxEvent in recentEvents) {
             MXRoom *mxRoom = [mxHandler.mxSession roomWithRoomId:mxEvent.roomId];
             
             NSArray* membersList = [mxRoom.state members];
             
             // keep only 1:1 chat
             if ([mxRoom.state members].count <= 2) {
                 
                 for (MXRoomMember* member in membersList) {
                     // not myself
                     if (![member.userId isEqualToString:mxHandler.userId]) {
                         if ([matrixIDs indexOfObject:member.userId] == NSNotFound) {
                             [matrixIDs addObject:member.userId];
                         }
                     }
                 }
             }
         }
     }
    
    return matrixIDs;
}

- (NSString*)privateOneToOneRoomIdWithUserId:(NSString*)userId {
    if (self.mxSession) {
        // List the last messages of each room to get the rooms list in chronological order
        NSArray *recentEvents = [NSMutableArray arrayWithArray:[self.mxSession recentsWithTypeIn:self.eventsFilterForMessages]];
        
        // Loops
        for (MXEvent *mxEvent in recentEvents) {
            // Get the dedicated mxRooms
            MXRoom *mxRoom = [self.mxSession roomWithRoomId:mxEvent.roomId];
            
            // Consider only private room with 2 users
            if (!mxRoom.state.isPublic && mxRoom.state.members.count == 2) {
                NSArray* roomMembers = mxRoom.state.members;
                
                // Check whether the provided userId is one of them
                MXRoomMember* member = nil;
                MXRoomMember* member1 = [roomMembers objectAtIndex:0];
                if ([member1.userId isEqualToString:userId]) {
                    member = member1;
                } else {
                    MXRoomMember* member2 = [roomMembers objectAtIndex:1];
                    if ([member2.userId isEqualToString:userId]) {
                        member = member2;
                    }
                }
                
                if (member) {
                    // Check the membership of this member (Indeed the room should be ignored if the member left it)
                    if (member.membership != MXMembershipLeave && member.membership != MXMembershipBan) {
                        // We found the right room
                        return mxRoom.state.roomId;
                    }
                }
            }
        }
    }
    
    return nil;
}

- (void)startPrivateOneToOneRoomWithUserId:(NSString*)userId {
    if (self.mxRestClient) {
        NSString* roomId = [self privateOneToOneRoomIdWithUserId:userId];
        
        // if the room exists
        if (roomId) {
            // open it
            [[AppDelegate theDelegate].masterTabBarController showRoom:roomId];
        } else {
            // create a new room
            [self.mxRestClient createRoom:nil
                                    visibility:kMXRoomVisibilityPrivate
                                     roomAlias:nil
                                         topic:nil
                                       success:^(MXCreateRoomResponse *response) {
                                           // invite the other user only if it is defined and not onself
                                           if (userId && ![self.userId isEqualToString:userId]) {
                                               // add the user
                                               [self.mxRestClient inviteUser:userId toRoom:response.roomId success:^{
                                               } failure:^(NSError *error) {
                                                   NSLog(@"[MatrixSDKHandler] %@ invitation failed (roomId: %@): %@", userId, response.roomId, error);
                                                   //Alert user
                                                   [[AppDelegate theDelegate] showErrorAsAlert:error];
                                               }];
                                           }
                                           
                                           // Open created room
                                           [[AppDelegate theDelegate].masterTabBarController showRoom:response.roomId];
                                           
                                       } failure:^(NSError *error) {
                                           NSLog(@"[MatrixSDKHandler] Create room failed: %@", error);
                                           //Alert user
                                           [[AppDelegate theDelegate] showErrorAsAlert:error];
                                       }];
        }
    }
}

- (void)restoreInAppNotificationsForRoomId:(NSString*)roomID {
    if (roomID) {
        // Enable inApp notification for this room
        [self.unnotifiedRooms removeObject:roomID];
    }
}

- (void)storePartialTextMessage:(NSString*)textMessage forRoomId:(NSString*)roomId {
    if (roomId) {
        if (textMessage.length) {
            [self.partialTextMsgByRoomId setObject:textMessage forKey:roomId];
        } else {
            [self.partialTextMsgByRoomId removeObjectForKey:roomId];
        }
    }
}

- (NSString*)partialTextMessageForRoomId:(NSString*)roomId {
    if (roomId) {
        return [self.partialTextMsgByRoomId objectForKey:roomId];
    }
    return nil;
}

- (CGFloat)getPowerLevel:(MXRoomMember *)roomMember inRoom:(MXRoom *)room {
    CGFloat powerLevel = 0;
    
    // Customize banned and left (kicked) members
    if (roomMember.membership == MXMembershipLeave || roomMember.membership == MXMembershipBan) {
        powerLevel = 0;
    } else {
        // Handle power level display
        //self.userPowerLevel.hidden = NO;
        MXRoomPowerLevels *roomPowerLevels = room.state.powerLevels;
        
        int maxLevel = 0;
        for (NSString *powerLevel in roomPowerLevels.users.allValues) {
            int level = [powerLevel intValue];
            if (level > maxLevel) {
                maxLevel = level;
            }
        }
        NSUInteger userPowerLevel = [roomPowerLevels powerLevelOfUserWithUserID:roomMember.userId];
        float userPowerLevelFloat = 0.0;
        if (userPowerLevel) {
            userPowerLevelFloat = userPowerLevel;
        }
        
        powerLevel = maxLevel ? userPowerLevelFloat / maxLevel : 1;
    }
    
    return powerLevel;
}

#pragma mark - Event handling

// Checks whether the event is related to an attachment and if it is supported
- (BOOL)isSupportedAttachment:(MXEvent*)event {
    BOOL isSupportedAttachment = NO;
    
    if (event.eventType == MXEventTypeRoomMessage) {
        NSString *msgtype = event.content[@"msgtype"];
        NSString *requiredField;
        
        if ([msgtype isEqualToString:kMXMessageTypeImage]) {
            requiredField = event.content[@"url"];
            if (requiredField.length) {
                isSupportedAttachment = YES;
            }
        } else if ([msgtype isEqualToString:kMXMessageTypeAudio]) {
            // Not supported yet
        } else if ([msgtype isEqualToString:kMXMessageTypeVideo]) {
            requiredField = event.content[@"url"];
            if (requiredField) {
                isSupportedAttachment = YES;
            }
        } else if ([msgtype isEqualToString:kMXMessageTypeLocation]) {
            // Not supported yet
        }
    }
    return isSupportedAttachment;
}

// Check whether the event is emote event
- (BOOL)isEmote:(MXEvent*)event {
    if (event.eventType == MXEventTypeRoomMessage) {
        NSString *msgtype = event.content[@"msgtype"];
        if ([msgtype isEqualToString:kMXMessageTypeEmote]) {
            return YES;
        }
    }
    return NO;
}

- (NSString*)senderDisplayNameForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState {
    // Consider first the current display name defined in provided room state (Note: this room state is supposed to not take the new event into account)
    NSString *senderDisplayName = [roomState memberName:event.userId];
    // Check whether this sender name is updated by the current event (This happens in case of new joined member)
    if ([event.content[@"displayname"] length]) {
        // Use the actual display name
        senderDisplayName = event.content[@"displayname"];
    }
    return senderDisplayName;
}

- (NSString*)senderAvatarUrlForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState {
    // Consider first the avatar url defined in provided room state (Note: this room state is supposed to not take the new event into account)
    NSString *senderAvatarUrl = [roomState memberWithUserId:event.userId].avatarUrl;
    // Check whether this avatar url is updated by the current event (This happens in case of new joined member)
    if ([event.content[@"avatar_url"] length]) {
        // Use the actual display name
        senderAvatarUrl = event.content[@"avatar_url"];
    }
    return senderAvatarUrl;
}

#pragma mark - Presence

// return the presence ring color
// nil means there is no ring to display
- (UIColor*)getPresenceRingColor:(MXPresence)presence {
    switch (presence) {
        case MXPresenceOnline:
            return [UIColor colorWithRed:0.2 green:0.9 blue:0.2 alpha:1.0];
        case MXPresenceUnavailable:
            return [UIColor colorWithRed:0.9 green:0.9 blue:0.0 alpha:1.0];
        case MXPresenceOffline:
            return [UIColor colorWithRed:0.9 green:0.2 blue:0.2 alpha:1.0];
        case MXPresenceUnknown:
        case MXPresenceFreeForChat:
        case MXPresenceHidden:
        default:
            return nil;
    }
}

#pragma mark - Bing work

// return YES if the text contains a bing word
- (BOOL)containsBingWord:(NSString*)text {
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    NSMutableArray* wordsList = [NSMutableArray array];
    
    // add the display name
    if (mxHandler.mxSession.myUser.displayname.length) {
        [wordsList addObject:mxHandler.mxSession.myUser.displayname];
    }
    
    // and the user identifiers
    if (mxHandler.localPartFromUserId.length) {
        [wordsList addObject:mxHandler.localPartFromUserId];
    }
    
    if (wordsList.count > 0) {
        NSMutableString* pattern = [[NSMutableString alloc] init];
        
        [pattern appendString:@"("];
        
        for(NSString* word in wordsList) {
            // check it is a regex
            if ([pattern hasPrefix:@"\\b"] && [pattern hasSuffix:@"\\b"]) {
                [pattern appendFormat:@"%@|", word];
            } else {
                [pattern appendFormat:@"\\b%@\\b|", word];
            }
        }
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"%@)", [pattern substringToIndex:pattern.length - 1]] options:NSRegularExpressionCaseInsensitive error:nil];
        if ([regex numberOfMatchesInString:text options:0 range:NSMakeRange(0, [text length])]) {
            return YES;
        }
    }
    return NO;
}

@end
