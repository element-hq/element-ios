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
#import "MXCAlert.h"

#import "MXFileStore.h"
#import "MXTools.h"

#import "MediaManager.h"

NSString *const kMatrixSDKHandlerUnsupportedEventDescriptionPrefix = @"Unsupported event: ";

static MatrixSDKHandler *sharedHandler = nil;

@interface MatrixSDKHandler () {
    // We will notify user only once on session failure
    BOOL notifyOpenSessionFailure;
    
    // Handle user's settings change
    id userUpdateListener;
    // Handle events notification
    id eventsListener;
}

@property (strong, nonatomic) MXFileStore *mxFileStore;
@property (nonatomic,readwrite) MatrixSDKHandlerStatus status;
@property (nonatomic,readwrite) BOOL isResumeDone;
@property (strong, nonatomic) MXCAlert *mxNotification;
@property (nonatomic) UIBackgroundTaskIdentifier bgTask;

// when the user cancels a notification
// assume that any messagge room will be ignored
// until the next launch / debackground
@property (nonatomic,readwrite) NSMutableArray* unnotifiedRooms;
@end

@implementation MatrixSDKHandler

@synthesize homeServerURL, homeServer, userLogin, userId, accessToken;

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
        _status = (self.accessToken != nil) ? MatrixSDKHandlerStatusLogged : MatrixSDKHandlerStatusLoggedOut;
        _isResumeDone = NO;
        _userPresence = MXPresenceUnknown;
        notifyOpenSessionFailure = YES;
        
        NSString *label = [NSString stringWithFormat:@"com.matrix.%@.MatrixSDKHandler", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];
        _processingQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        
        // Read potential homeserver url in shared defaults object
        if (self.homeServerURL) {
            self.mxRestClient = [[MXRestClient alloc] initWithHomeServer:self.homeServerURL];
            
            if (self.accessToken) {
                [self openSession];
            }
        }
        
        _unnotifiedRooms = [[NSMutableArray alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)openSession {
    MXCredentials *credentials = [[MXCredentials alloc] initWithHomeServer:self.homeServerURL
                                                                    userId:self.userId
                                                               accessToken:self.accessToken];
    
    self.mxRestClient = [[MXRestClient alloc] initWithCredentials:credentials];
    if (self.mxRestClient) {
        // Use MXFileStore as MXStore to permanently store events
        _mxFileStore = [[MXFileStore alloc] init];

        [_mxFileStore openWithCredentials:credentials onComplete:^{
            self.mxSession = [[MXSession alloc] initWithMatrixRestClient:self.mxRestClient andStore:_mxFileStore];
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
                                                 kMXEventTypeStringRoomMessage,
                                                 kMXEventTypeStringRoomRedaction
                                                 ];
            }

            // Launch mxSession
            [self.mxSession start:^{
                self.status = MatrixSDKHandlerStatusStoreDataReady;
            } onServerSyncDone:^{
                _isResumeDone = YES;
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
                NSLog(@"Initial Sync failed: %@", error);
                if (notifyOpenSessionFailure) {
                    //Alert user only once
                    notifyOpenSessionFailure = NO;
                    [[AppDelegate theDelegate] showErrorAsAlert:error];
                }
                
                // Postpone a new attempt in 10 sec 
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self openSession];
                });
            }];
        }];
        
    }
}

- (void)closeSession {
    if (eventsListener) {
        [self.mxSession removeListener:eventsListener];
        eventsListener = nil;
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
    } else {
        self.mxRestClient = nil;
    }
    
    _isResumeDone = NO;
    notifyOpenSessionFailure = YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _processingQueue = nil;
    
    [self closeSession];
    self.mxSession = nil;
    
    if (self.mxNotification) {
        [self.mxNotification dismiss:NO];
        self.mxNotification = nil;
    }
}

- (void)onAppDidEnterBackground {
    // Hide potential notification
    if (self.mxNotification) {
        [self.mxNotification dismiss:NO];
        self.mxNotification = nil;
    }
    
    _unnotifiedRooms = [[NSMutableArray alloc] init];
}

#pragma mark -

- (void)pauseInBackgroundTask {
    if (self.mxSession && self.status == MatrixSDKHandlerStatusServerSyncDone) {
        _bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
            _bgTask = UIBackgroundTaskInvalid;
            
            NSLog(@"pauseInBackgroundTask : %08lX expired", (unsigned long)_bgTask);
        }];
        
        NSLog(@"pauseInBackgroundTask : %08lX starts", (unsigned long)_bgTask);
        // Pause SDK
        [self.mxSession pause];
        self.isResumeDone = NO;
        // Update user presence
        __weak typeof(self) weakSelf = self;
        [self setUserPresence:MXPresenceUnavailable andStatusMessage:nil completion:^{
            NSLog(@"pauseInBackgroundTask : %08lX ends", (unsigned long)weakSelf.bgTask);
            [[UIApplication sharedApplication] endBackgroundTask:weakSelf.bgTask];
            weakSelf.bgTask = UIBackgroundTaskInvalid;
            NSLog(@">>>>> background pause task finished");
        }];
    }
}

- (void)resume {
    if (self.mxSession && self.status == MatrixSDKHandlerStatusServerSyncDone) {
        if (!self.isResumeDone) {
            // Resume SDK and update user presence
            [self.mxSession resume:^{
                [self setUserPresence:MXPresenceOnline andStatusMessage:nil completion:nil];
                self.isResumeDone = YES;
            }];
        }
        
        if (_bgTask) {
            // Cancel background task
            [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
            _bgTask = UIBackgroundTaskInvalid;
            NSLog(@"pauseInBackgroundTask : %08lX cancelled", (unsigned long)_bgTask);
        }
    }
}

- (void)logout {
    //[self setUserPresence:MXPresenceOffline andStatusMessage:nil completion:nil];
    
    // Reset access token (mxSession is closed by setter)
    self.accessToken = nil;
    self.userId = nil;
    self.homeServer = nil;
    // Keep userLogin, homeServerUrl
}

- (void)forceInitialSync:(BOOL)clearCache {
    if (self.status == MatrixSDKHandlerStatusServerSyncDone || self.status == MatrixSDKHandlerStatusStoreDataReady) {
        self.status = MatrixSDKHandlerStatusLogged;
        [self closeSession];
        notifyOpenSessionFailure = NO;
        
        // Force back to Recents list if room details is displayed (Room details are not available until the end of initial sync)
        [[AppDelegate theDelegate].masterTabBarController popRoomViewControllerAnimated:NO];
        
        if (clearCache) {
            // clear the media cache
            [MediaManager clearCache];
            
            [_mxFileStore deleteAllData];
        }
        
        if (self.accessToken) {
            [self openSession];
        }
    }
}

- (void)enableInAppNotifications:(BOOL)isEnabled {
    if (isEnabled) {
        // Register events listener
        eventsListener = [self.mxSession listenToEventsOfTypes:self.eventsFilterForMessages onEvent:^(MXEvent *event, MXEventDirection direction, id customObject) {
            // Consider only live event
            if (direction == MXEventDirectionForwards) {
                MXRoomState* roomState = (MXRoomState*)customObject;
                // If we are running on background, show a local notif
                if (UIApplicationStateBackground == [UIApplication sharedApplication].applicationState) {
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
                    localNotification.hasAction = YES;
                    [localNotification setAlertBody:[self displayTextForEvent:event withRoomState:roomState inSubtitleMode:YES]];
                    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                } else if (![event.userId isEqualToString:self.userId]
                           && ![[AppDelegate theDelegate].masterTabBarController.visibleRoomId isEqualToString:event.roomId]
                           && ![[AppDelegate theDelegate].masterTabBarController isPresentingMediaPicker]
                           && ([self.unnotifiedRooms indexOfObject:event.roomId] == NSNotFound)) {
                    
                    NSString* messageText = [self displayTextForEvent:event withRoomState:roomState inSubtitleMode:YES];
                    
                    // display the alert only the text contains an expected word
                    if ((0 == [AppSettings sharedSettings].specificWordsToAlertOn.count) ||[self containsBingWord:messageText]) {
                        // The sender is not the user and the concerned room is not presently visible,
                        // we display a notification by removing existing one (if any)
                        if (self.mxNotification) {
                            [self.mxNotification dismiss:NO];
                        }
                        
                        __weak typeof(self) weakSelf = self;
                        
                        self.mxNotification = [[MXCAlert alloc] initWithTitle:roomState.displayname
                                                                         message:messageText
                                                                           style:MXCAlertStyleAlert];
                        self.mxNotification.cancelButtonIndex = [self.mxNotification addActionWithTitle:@"Cancel"
                                                                                                  style:MXCAlertActionStyleDefault
                                                                                                handler:^(MXCAlert *alert) {
                                                                                                    [MatrixSDKHandler sharedHandler].mxNotification = nil;
                                                                                                    
                                                                                                    [weakSelf.unnotifiedRooms addObject:event.roomId];
                                                                                                }];
                        [self.mxNotification addActionWithTitle:@"View"
                                                          style:MXCAlertActionStyleDefault
                                                        handler:^(MXCAlert *alert) {
                                                            [MatrixSDKHandler sharedHandler].mxNotification = nil;
                                                            // Show the room
                                                            [[AppDelegate theDelegate].masterTabBarController showRoom:event.roomId];
                                                        }];
                        
                        [self.mxNotification showInViewController:[[AppDelegate theDelegate].masterTabBarController selectedViewController]];
                    }
                }
            }
        }];
    } else {
        if (eventsListener) {
            [self.mxSession removeListener:eventsListener];
            eventsListener = nil;
        }
        if (self.mxNotification) {
            [self.mxNotification dismiss:NO];
            self.mxNotification = nil;
        }
    }
}

#pragma mark - Properties

- (NSString *)homeServerURL {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"homeserverurl"];
}

- (void)setHomeServerURL:(NSString *)inHomeserverURL {
    if (inHomeserverURL.length) {
        [[NSUserDefaults standardUserDefaults] setObject:inHomeserverURL forKey:@"homeserverurl"];
        self.mxRestClient = [[MXRestClient alloc] initWithHomeServer:inHomeserverURL];
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
        self.status = MatrixSDKHandlerStatusLoggedOut;
        [self closeSession];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Matrix user's settings

- (void)setUserPresence:(MXPresence)userPresence andStatusMessage:(NSString *)statusMessage completion:(void (^)(void))completion {
    self.userPresence = userPresence;
    // Update user presence on server side
    [self.mxSession.myUser setPresence:userPresence andStatusMessage:statusMessage success:^{
        NSLog(@"Set user presence (%lu) succeeded", (unsigned long)userPresence);
        if (completion) {
            completion();
        }
    } failure:^(NSError *error) {
        NSLog(@"Set user presence (%lu) failed: %@", (unsigned long)userPresence, error);
    }];
}

#pragma mark - events handler

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

#pragma mark -

// return a MatrixIDs list of 1:1 room members
- (NSArray*)oneToOneRoomMemberMatrixIDs {
    
    NSMutableArray* matrixIDs = [[NSMutableArray alloc] init];
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    
     if ((mxHandler.status == MatrixSDKHandlerStatusStoreDataReady) || (mxHandler.status == MatrixSDKHandlerStatusServerSyncDone)) {
      
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

// search if a private room has been started with this user
// returns the room ID
// nil if not found
- (NSString*) privateRoomIdWith:(NSString*)otherMatrixID {
    //
    if (self.mxSession) {
        // list the last messages of each room to get the rooms list
        NSArray *recentEvents = [NSMutableArray arrayWithArray:[self.mxSession recentsWithTypeIn:self.eventsFilterForMessages]];
        
        // loops
        for (MXEvent *mxEvent in recentEvents) {
            // get the dedicated mxRooms
            MXRoom *mxRoom = [self.mxSession roomWithRoomId:mxEvent.roomId];
            
            // accept only room with 2 users
            if (mxRoom.state.members.count == 2) {
                NSArray* roomMembers = mxRoom.state.members;
                
                MXRoomMember* member1 = [roomMembers objectAtIndex:0];
                MXRoomMember* member2 = [roomMembers objectAtIndex:1];
                
                // check if they are the dedicated users
                if (
                    ([member1.userId isEqualToString:self.mxSession.myUser.userId] || [member1.userId isEqualToString:otherMatrixID]) &&
                    ([member2.userId isEqualToString:self.mxSession.myUser.userId] || [member2.userId isEqualToString:otherMatrixID])) {
                    return mxRoom.state.roomId;
                }
            }
        }
    }
    
    return nil;
}

// create a private one to one chat room
- (void)startPrivateOneToOneRoomWith:(NSString*)otherMatrixID {
    if (self.mxRestClient) {
        NSString* roomId = [self privateRoomIdWith:otherMatrixID];
        
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
                                           if (otherMatrixID && ![self.userId isEqualToString:otherMatrixID]) {
                                               // add the user
                                               [self.mxRestClient inviteUser:otherMatrixID toRoom:response.roomId success:^{
                                               } failure:^(NSError *error) {
                                                   NSLog(@"%@ invitation failed (roomId: %@): %@", otherMatrixID, response.roomId, error);
                                                   //Alert user
                                                   [[AppDelegate theDelegate] showErrorAsAlert:error];
                                               }];
                                           }
                                           
                                           // Open created room
                                           [[AppDelegate theDelegate].masterTabBarController showRoom:response.roomId];
                                           
                                       } failure:^(NSError *error) {
                                           NSLog(@"Create room failed: %@", error);
                                           //Alert user
                                           [[AppDelegate theDelegate] showErrorAsAlert:error];
                                       }];
        }
    }
}

- (NSString*)thumbnailURLForContent:(NSString*)contentURI inViewSize:(CGSize)viewSize withMethod:(MXThumbnailingMethod)thumbnailingMethod {
    // Suppose this url is a matrix content uri, we use SDK to get the well adapted thumbnail from server
    // Convert first the provided size in pixels
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGSize sizeInPixels = CGSizeMake(viewSize.width * scale, viewSize.height * scale);
    NSString *thumbnailURL = [self.mxRestClient urlOfContentThumbnail:contentURI withSize:sizeInPixels andMethod:thumbnailingMethod];
    if (nil == thumbnailURL) {
        // Manage backward compatibility. The content URL used to be an absolute HTTP URL
        thumbnailURL = contentURI;
    }
    return thumbnailURL;
}

#pragma mark -

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

- (NSString*)displayTextForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState inSubtitleMode:(BOOL)isSubtitle {
    // Check first whether the event has been redacted
    NSString *redactedInfo = nil;
    BOOL isRedacted = (event.redactedBecause != nil);
    if (isRedacted) {
        NSLog(@"Redacted event %@ (%@)", event.description, event.redactedBecause);
        // Check whether redacted information is required
        if (!isSubtitle && ![AppSettings sharedSettings].hideRedactedInformation) {
            redactedInfo = @"<redacted>";
            if ([event.redactedBecause isKindOfClass:[NSDictionary class]]) {
                NSString *redactedBy = [roomState memberName:event.redactedBecause[@"user_id"]];
                NSString *redactedReason = event.redactedBecause[@"reason"];
                if (redactedReason.length) {
                    if (redactedBy.length) {
                        redactedBy = [NSString stringWithFormat:@"by %@ (reason: %@)", redactedBy, redactedReason];
                    } else {
                        redactedBy = [NSString stringWithFormat:@"(reason: %@)", redactedReason];
                    }
                } else if (redactedBy.length) {
                    redactedBy = [NSString stringWithFormat:@"by %@", redactedBy];
                }
                
                if (redactedBy.length) {
                    redactedInfo = [NSString stringWithFormat:@"<redacted %@>", redactedBy];
                }
            }
        }
    }
    
    // Prepare returned description
    NSString *displayText = nil;
    // Prepare display name for concerned users
    NSString *senderDisplayName = [self senderDisplayNameForEvent:event withRoomState:roomState];
    NSString *targetDisplayName = nil;
    if (event.stateKey) {
        targetDisplayName = [roomState memberName:event.stateKey];
    }
    
    switch (event.eventType) {
        case MXEventTypeRoomName: {
            NSString *roomName = event.content[@"name"];
            if (isRedacted) {
                if (!redactedInfo) {
                    // Here the event is ignored (no display)
                    return nil;
                }
                roomName = redactedInfo;
            }
            
            if (roomName.length) {
                displayText = [NSString stringWithFormat:@"%@ changed the room name to: %@", senderDisplayName, roomName];
            } else {
                displayText = [NSString stringWithFormat:@"%@ removed the room name", senderDisplayName];
            }
            break;
        }
        case MXEventTypeRoomTopic: {
            NSString *roomTopic = event.content[@"topic"];
            if (isRedacted) {
                if (!redactedInfo) {
                    // Here the event is ignored (no display)
                    return nil;
                }
                roomTopic = redactedInfo;
            }
            
            if (roomTopic.length) {
                displayText = [NSString stringWithFormat:@"%@ changed the topic to: %@", senderDisplayName, roomTopic];
            } else {
                displayText = [NSString stringWithFormat:@"%@ removed the topic", senderDisplayName];
            }
            
            break;
        }
        case MXEventTypeRoomMember: {
            // Presently only change on membership, display name and avatar are supported
            
            // Retrieve membership
            NSString* membership = event.content[@"membership"];
            NSString *prevMembership = nil;
            if (event.prevContent) {
                prevMembership = event.prevContent[@"membership"];
            }
            
            // Check whether the sender has updated his profile (the membership is then unchanged)
            if (prevMembership && membership && [membership isEqualToString:prevMembership]) {
                // Is redacted event?
                if (isRedacted) {
                    if (!redactedInfo) {
                        // Here the event is ignored (no display)
                        return nil;
                    }
                    displayText = [NSString stringWithFormat:@"%@ updated their profile %@", senderDisplayName, redactedInfo];;
                } else {
                    // Check whether the display name has been changed
                    NSString *displayname = event.content[@"displayname"];
                    NSString *prevDisplayname =  event.prevContent[@"displayname"];
                    if (!displayname.length) {
                        displayname = nil;
                    }
                    if (!prevDisplayname.length) {
                        prevDisplayname = nil;
                    }
                    if ((displayname || prevDisplayname) && ([displayname isEqualToString:prevDisplayname] == NO)) {
                        if (!prevDisplayname) {
                            displayText = [NSString stringWithFormat:@"%@ set their display name to %@", event.userId, displayname];
                        } else if (!displayname) {
                            displayText = [NSString stringWithFormat:@"%@ removed their display name (previouly named %@)", event.userId, prevDisplayname];
                        } else {
                            displayText = [NSString stringWithFormat:@"%@ changed their display name from %@ to %@", event.userId, prevDisplayname, displayname];
                        }
                    }
                    
                    // Check whether the avatar has been changed
                    NSString *avatar = event.content[@"avatar_url"];
                    NSString *prevAvatar = event.prevContent[@"avatar_url"];
                    if (!avatar.length) {
                        avatar = nil;
                    }
                    if (!prevAvatar.length) {
                        prevAvatar = nil;
                    }
                    if ((prevAvatar || avatar) && ([avatar isEqualToString:prevAvatar] == NO)) {
                        if (displayText) {
                            displayText = [NSString stringWithFormat:@"%@ (picture profile was changed too)", displayText];
                        } else {
                            displayText = [NSString stringWithFormat:@"%@ changed their picture profile", senderDisplayName];
                        }
                    }
                }
            } else {
                // Consider here a membership change
                if ([membership isEqualToString:@"invite"]) {
                    displayText = [NSString stringWithFormat:@"%@ invited %@", senderDisplayName, targetDisplayName];
                } else if ([membership isEqualToString:@"join"]) {
                    displayText = [NSString stringWithFormat:@"%@ joined", senderDisplayName];
                } else if ([membership isEqualToString:@"leave"]) {
                    if ([event.userId isEqualToString:event.stateKey]) {
                        displayText = [NSString stringWithFormat:@"%@ left", senderDisplayName];
                    } else if (prevMembership) {
                        if ([prevMembership isEqualToString:@"join"] || [prevMembership isEqualToString:@"invite"]) {
                            displayText = [NSString stringWithFormat:@"%@ kicked %@", senderDisplayName, targetDisplayName];
                            if (event.content[@"reason"]) {
                                displayText = [NSString stringWithFormat:@"%@: %@", displayText, event.content[@"reason"]];
                            }
                        } else if ([prevMembership isEqualToString:@"ban"]) {
                            displayText = [NSString stringWithFormat:@"%@ unbanned %@", senderDisplayName, targetDisplayName];
                        }
                    }
                } else if ([membership isEqualToString:@"ban"]) {
                    displayText = [NSString stringWithFormat:@"%@ banned %@", senderDisplayName, targetDisplayName];
                    if (event.content[@"reason"]) {
                        displayText = [NSString stringWithFormat:@"%@: %@", displayText, event.content[@"reason"]];
                    }
                }
                
                // Append redacted info if any
                if (redactedInfo) {
                    displayText = [NSString stringWithFormat:@"%@ %@", displayText, redactedInfo];
                }
            }
            break;
        }
        case MXEventTypeRoomCreate: {
            NSString *creatorId = event.content[@"creator"];
            if (creatorId) {
                displayText = [NSString stringWithFormat:@"%@ created the room", [roomState memberName:creatorId]];
                // Append redacted info if any
                if (redactedInfo) {
                    displayText = [NSString stringWithFormat:@"%@ %@", displayText, redactedInfo];
                }
            }
            break;
        }
        case MXEventTypeRoomJoinRules: {
            NSString *joinRule = event.content[@"join_rule"];
            if (joinRule) {
                displayText = [NSString stringWithFormat:@"The join rule is: %@", joinRule];
                // Append redacted info if any
                if (redactedInfo) {
                    displayText = [NSString stringWithFormat:@"%@ %@", displayText, redactedInfo];
                }
            }
            break;
        }
        case MXEventTypeRoomPowerLevels: {
            displayText = @"The power level of room members are:";
            NSDictionary *users = event.content[@"users"];
            for (NSString *key in users.allKeys) {
                displayText = [NSString stringWithFormat:@"%@\r\n\u2022 %@: %@", displayText, key, [users objectForKey:key]];
            }
            if (event.content[@"users_default"]) {
                displayText = [NSString stringWithFormat:@"%@\r\n\u2022 %@: %@", displayText, @"default", event.content[@"users_default"]];
            }
            
            displayText = [NSString stringWithFormat:@"%@\r\nThe minimum power levels that a user must have before acting are:", displayText];
            if (event.content[@"ban"]) {
                displayText = [NSString stringWithFormat:@"%@\r\n\u2022 ban: %@", displayText, event.content[@"ban"]];
            }
            if (event.content[@"kick"]) {
                displayText = [NSString stringWithFormat:@"%@\r\n\u2022 kick: %@", displayText, event.content[@"kick"]];
            }
            if (event.content[@"redact"]) {
                displayText = [NSString stringWithFormat:@"%@\r\n\u2022 redact: %@", displayText, event.content[@"redact"]];
            }
            if (event.content[@"invite"]) {
                displayText = [NSString stringWithFormat:@"%@\r\n\u2022 invite: %@", displayText, event.content[@"invite"]];
            }
            
            displayText = [NSString stringWithFormat:@"%@\r\nThe minimum power levels related to events are:", displayText];
            NSDictionary *events = event.content[@"events"];
            for (NSString *key in events.allKeys) {
                displayText = [NSString stringWithFormat:@"%@\r\n\u2022 %@: %@", displayText, key, [events objectForKey:key]];
            }
            if (event.content[@"events_default"]) {
                displayText = [NSString stringWithFormat:@"%@\r\n\u2022 %@: %@", displayText, @"events_default", event.content[@"events_default"]];
            }
            if (event.content[@"state_default"]) {
                displayText = [NSString stringWithFormat:@"%@\r\n\u2022 %@: %@", displayText, @"state_default", event.content[@"state_default"]];
            }
            
            // Append redacted info if any
            if (redactedInfo) {
                displayText = [NSString stringWithFormat:@"%@\r\n %@", displayText, redactedInfo];
            }
            break;
        }
        case MXEventTypeRoomAliases: {
            NSArray *aliases = event.content[@"aliases"];
            if (aliases) {
                displayText = [NSString stringWithFormat:@"The room aliases are: %@", aliases];
                // Append redacted info if any
                if (redactedInfo) {
                    displayText = [NSString stringWithFormat:@"%@\r\n %@", displayText, redactedInfo];
                }
            }
            break;
        }
        case MXEventTypeRoomMessage: {
            // Is redacted?
            if (isRedacted) {
                if (!redactedInfo) {
                    // Here the event is ignored (no display)
                    return nil;
                }
                displayText = redactedInfo;
            } else {
                NSString *msgtype = event.content[@"msgtype"];
                displayText = [event.content[@"body"] isKindOfClass:[NSString class]] ? event.content[@"body"] : nil;
                
                if ([msgtype isEqualToString:kMXMessageTypeEmote]) {
                    displayText = [NSString stringWithFormat:@"* %@ %@", senderDisplayName, displayText];
                } else if ([msgtype isEqualToString:kMXMessageTypeImage]) {
                    displayText = displayText? displayText : @"image attachment";
                    // Check attachment validity
                    if (![self isSupportedAttachment:event]) {
                        NSLog(@"ERROR: Unsupported attachment %@", event.description);
                        // Check whether unsupported/unexpected messages should be exposed
                        if (isSubtitle || [AppSettings sharedSettings].hideUnsupportedEvents) {
                            displayText = @"invalid image attachment";
                        } else {
                            // Display event content as unsupported event
                            displayText = [NSString stringWithFormat:@"%@%@", kMatrixSDKHandlerUnsupportedEventDescriptionPrefix, event.description];
                        }
                    }
                } else if ([msgtype isEqualToString:kMXMessageTypeAudio]) {
                    displayText = displayText? displayText : @"audio attachment";
                    if (![self isSupportedAttachment:event]) {
                        NSLog(@"ERROR: Unsupported attachment %@", event.description);
                        if (isSubtitle || [AppSettings sharedSettings].hideUnsupportedEvents) {
                            displayText = @"invalid audio attachment";
                        } else {
                            displayText = [NSString stringWithFormat:@"%@%@", kMatrixSDKHandlerUnsupportedEventDescriptionPrefix, event.description];
                        }
                    }
                } else if ([msgtype isEqualToString:kMXMessageTypeVideo]) {
                    displayText = displayText? displayText : @"video attachment";
                    if (![self isSupportedAttachment:event]) {
                        NSLog(@"ERROR: Unsupported attachment %@", event.description);
                        if (isSubtitle || [AppSettings sharedSettings].hideUnsupportedEvents) {
                            displayText = @"invalid video attachment";
                        } else {
                            displayText = [NSString stringWithFormat:@"%@%@", kMatrixSDKHandlerUnsupportedEventDescriptionPrefix, event.description];
                        }
                    }
                } else if ([msgtype isEqualToString:kMXMessageTypeLocation]) {
                    displayText = displayText? displayText : @"location attachment";
                    if (![self isSupportedAttachment:event]) {
                        NSLog(@"ERROR: Unsupported attachment %@", event.description);
                        if (isSubtitle || [AppSettings sharedSettings].hideUnsupportedEvents) {
                            displayText = @"invalid location attachment";
                        } else {
                            displayText = [NSString stringWithFormat:@"%@%@", kMatrixSDKHandlerUnsupportedEventDescriptionPrefix, event.description];
                        }
                    }
                }
                
                // Check whether the sender name has to be added
                if (displayText && isSubtitle && [msgtype isEqualToString:kMXMessageTypeEmote] == NO) {
                    displayText = [NSString stringWithFormat:@"%@: %@", senderDisplayName, displayText];
                }
            }
            break;
        }
        case MXEventTypeRoomMessageFeedback: {
            NSString *type = event.content[@"type"];
            NSString *eventId = event.content[@"target_event_id"];
            if (type && eventId) {
                displayText = [NSString stringWithFormat:@"Feedback event (id: %@): %@", eventId, type];
                // Append redacted info if any
                if (redactedInfo) {
                    displayText = [NSString stringWithFormat:@"%@ %@", displayText, redactedInfo];
                }
            }
            break;
        }
        case MXEventTypeRoomRedaction: {
            if ([AppSettings sharedSettings].displayAllEvents) {
                NSString *eventId = event.redacts;
                displayText = [NSString stringWithFormat:@"%@ redacted an event (id: %@)", senderDisplayName, eventId];
            } else {
                // No description
                return nil;
            }
        }
        case MXEventTypeCustom:
            break;
        default:
            break;
    }
    
    if (!displayText) {
        NSLog(@"ERROR: Unsupported event %@)", event.description);
        if (!isSubtitle && ![AppSettings sharedSettings].hideUnsupportedEvents) {
            // Return event content as unsupported event
            displayText = [NSString stringWithFormat:@"%@%@", kMatrixSDKHandlerUnsupportedEventDescriptionPrefix, event.description];
        }
    }
    
    return displayText;
}

- (NSUInteger) MXCacheSize {
    
    if (self.mxFileStore) {
        return self.mxFileStore.diskUsage;
    }
    
    return 0;
}

- (NSUInteger) cachesSize {
    return self.MXCacheSize + [MediaManager cacheSize];
}

- (NSUInteger) minCachesSize {
    // add a 50MB margin to avoid cache file deletion
    return self.MXCacheSize + [MediaManager minCacheSize] + 50 * 1024 * 1024;
}

- (NSUInteger) currentMaxCachesSize {
    return self.MXCacheSize + [MediaManager currentMaxCacheSize];
}

- (void)setCurrentMaxCachesSize:(NSUInteger)maxCachesSize {
    [MediaManager setCurrentMaxCacheSize:maxCachesSize - self.MXCacheSize];
}

- (NSUInteger) maxAllowedCachesSize {
    return self.MXCacheSize + [MediaManager maxAllowedCacheSize];
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

// return YES if the text contains a bing word
- (BOOL)containsBingWord:(NSString*)text {
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    
    NSMutableArray* wordsList = [[AppSettings sharedSettings].specificWordsToAlertOn mutableCopy];
    
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
