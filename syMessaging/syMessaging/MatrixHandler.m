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

#import "MatrixHandler.h"
#import "AppDelegate.h"
#import "AppSettings.h"
#import "CustomAlert.h"

NSString *const kMatrixHandlerUnsupportedMessagePrefix = @"UNSUPPORTED MSG: ";

static MatrixHandler *sharedHandler = nil;

@interface MatrixHandler () {
    // We will notify user only once on session failure
    BOOL notifyOpenSessionFailure;
    
    // Handle user's settings change
    id roomMembersListener;
    // Handle events notification
    id eventsListener;
}

@property (nonatomic,readwrite) BOOL isInitialSyncDone;
@property (strong, nonatomic) CustomAlert *mxNotification;

@end

@implementation MatrixHandler

@synthesize homeServerURL, homeServer, userLogin, userId, accessToken;
@synthesize userDisplayName, userPictureURL;

+ (MatrixHandler *)sharedHandler {
    @synchronized(self) {
        if(sharedHandler == nil)
        {
            sharedHandler = [[super allocWithZone:NULL] init];
        }
    }
    return sharedHandler;
}

#pragma  mark - 

-(MatrixHandler *)init {
    if (self = [super init]) {
        _isInitialSyncDone = NO;
        notifyOpenSessionFailure = YES;
        
        // Read potential homeserver url in shared defaults object
        if (self.homeServerURL) {
            self.mxHomeServer = [[MXHomeServer alloc] initWithHomeServer:self.homeServerURL];
            
            if (self.accessToken) {
                [self openSession];
            }
        }
        // The app will look for user's display name in incoming messages, it must not be nil.
        if (self.userDisplayName == nil) {
            self.userDisplayName = @"";
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)openSession {
    self.mxSession = [[MXSession alloc] initWithHomeServer:self.homeServerURL userId:self.userId accessToken:self.accessToken];
    if (self.mxSession) {
        // Request user's display name
        [self.mxSession displayName:self.userId success:^(NSString *displayname) {
            self.userDisplayName = displayname;
        } failure:^(NSError *error) {
            NSLog(@"Get displayName failed: %@", error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
        
        self.mxData = [[MXData alloc] initWithMatrixSession:self.mxSession];
        // Check here whether the app user wants to display all the events
        if ([[AppSettings sharedSettings] displayAllEvents]) {
            // Override events filter to retrieve all the events
            self.mxData.eventsFilterForMessages = @[
                                                    kMXEventTypeStringRoomName,
                                                    kMXEventTypeStringRoomTopic,
                                                    kMXEventTypeStringRoomMember,
                                                    kMXEventTypeStringRoomCreate,
                                                    kMXEventTypeStringRoomJoinRules,
                                                    kMXEventTypeStringRoomPowerLevels,
                                                    kMXEventTypeStringRoomAddStateLevel,
                                                    kMXEventTypeStringRoomSendEventLevel,
                                                    kMXEventTypeStringRoomOpsLevel,
                                                    kMXEventTypeStringRoomAliases,
                                                    kMXEventTypeStringRoomMessage,
                                                    kMXEventTypeStringRoomMessageFeedback,
                                                    kMXEventTypeStringPresence
                                                    ];
        }
        // Launch mxData
        [self.mxData start:^{
            self.isInitialSyncDone = YES;
            
            // Register room members listener
            roomMembersListener = [self.mxData registerEventListenerForTypes:@[kMXEventTypeStringRoomMember] block:^(MXData *matrixData, MXEvent *event, BOOL isLive) {
                // Consider only live event
                if (isLive) {
                    // Consider only event from app user
                    if ([event.user_id isEqualToString:self.userId]) {
                        // Check whether this is a displayname change
                        if (event.prev_content) {
                            NSString *prevDisplayname = event.prev_content[@"displayname"];
                            NSString *displayname = event.content[@"displayname"];
                            if (prevDisplayname && displayname && [displayname isEqualToString:prevDisplayname] == NO) {
                                // Update local storage
                                self.userDisplayName = displayname;
                            }
                        }
                    }
                }
            }];
            
            // Check whether the app user wants notifications on new events
            if ([[AppSettings sharedSettings] enableNotifications]) {
                [self enableEventsNotifications:YES];
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
    }
}

- (void)closeSession {
    if (eventsListener) {
        [self.mxData unregisterListener:eventsListener];
        eventsListener = nil;
    }
    if (roomMembersListener) {
        [self.mxData unregisterListener:roomMembersListener];
        roomMembersListener = nil;
    }
    [self.mxData close];
    self.mxData = nil;
    [self.mxSession close];
    self.mxSession = nil;
    self.isInitialSyncDone = NO;
    notifyOpenSessionFailure = YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self closeSession];
    self.mxHomeServer = nil;
    
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
}

#pragma mark -

- (BOOL)isLogged {
    return (self.accessToken != nil);
}

- (void)logout {
    // Reset access token (mxSession is closed by setter)
    self.accessToken = nil;
    
    // Reset local storage of user's settings
    self.userDisplayName = @"";
    self.userPictureURL = nil;
}

- (void)forceInitialSync {
    [self closeSession];
    notifyOpenSessionFailure = NO;
    [self openSession];
}

- (void)enableEventsNotifications:(BOOL)isEnabled {
    if (isEnabled) {
        // Register events listener
        eventsListener = [self.mxData registerEventListenerForTypes:self.mxData.eventsFilterForMessages block:^(MXData *matrixData, MXEvent *event, BOOL isLive) {
            // Consider only live event
            if (isLive) {
                // If we are running on background, show a local notif
                if (UIApplicationStateBackground == [UIApplication sharedApplication].applicationState)
                {
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
                    localNotification.hasAction = YES;
                    [localNotification setAlertBody:[self displayTextFor:event inSubtitleMode:YES]];
                    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                } else if ([[AppDelegate theDelegate].masterTabBarController.visibleRoomId isEqualToString:event.room_id] == NO) {
                    // The concerned room is not presently visible, we display a notification by removing existing one (if any)
                    if (self.mxNotification) {
                        [self.mxNotification dismiss:NO];
                    }
                    
                    self.mxNotification = [[CustomAlert alloc] initWithTitle:[self.mxData getRoomData:event.room_id].displayname
                                                                     message:[self displayTextFor:event inSubtitleMode:YES]
                                                                       style:CustomAlertStyleAlert];
                    self.mxNotification.cancelButtonIndex = [self.mxNotification addActionWithTitle:@"OK"
                                                                                              style:CustomAlertActionStyleDefault
                                                                                            handler:^(CustomAlert *alert) {
                                                                                                [MatrixHandler sharedHandler].mxNotification = nil;
                                                                                            }];
                    [self.mxNotification addActionWithTitle:@"View"
                                                      style:CustomAlertActionStyleDefault
                                                    handler:^(CustomAlert *alert) {
                                                        [MatrixHandler sharedHandler].mxNotification = nil;
                                                        // Show the room
                                                        [[AppDelegate theDelegate].masterTabBarController showRoom:event.room_id];
                                                    }];
                    
                    [self.mxNotification showInViewController:[[AppDelegate theDelegate].masterTabBarController selectedViewController]];
                }
            }
        }];
    } else {
        if (eventsListener) {
            [self.mxData unregisterListener:eventsListener];
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
        self.mxHomeServer = [[MXHomeServer alloc] initWithHomeServer:inHomeserverURL];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"homeserverurl"];
        self.mxHomeServer = nil;
    }
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
}

- (NSString *)userId {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"userid"];
}

- (void)setUserId:(NSString *)inUserId {
    if (inUserId.length) {
        [[NSUserDefaults standardUserDefaults] setObject:inUserId forKey:@"userid"];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"userid"];
    }
}

- (NSString *)accessToken {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"accesstoken"];
}

- (void)setAccessToken:(NSString *)inAccessToken {
    if (inAccessToken.length) {
        [[NSUserDefaults standardUserDefaults] setObject:inAccessToken forKey:@"accesstoken"];
        [self openSession];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"accesstoken"];
        [self closeSession];
    }
}

#pragma mark - Matrix user's settings

- (NSString *)userDisplayName {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"userdisplayname"];
}

- (void)setUserDisplayName:(NSString *)inUserDisplayName {
    if ([inUserDisplayName isEqual:[NSNull null]] == NO && inUserDisplayName.length) {
        [[NSUserDefaults standardUserDefaults] setObject:inUserDisplayName forKey:@"userdisplayname"];
    } else {
        // the app will look for this display name in incoming messages, it must not be nil.
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"userdisplayname"];
    }
}

- (NSString *)userPictureURL {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"userpictureurl"];
}

- (void)setUserPictureURL:(NSString *)inUserPictureURL {
    if ([inUserPictureURL isEqual:[NSNull null]] == NO && inUserPictureURL.length) {
        [[NSUserDefaults standardUserDefaults] setObject:inUserPictureURL forKey:@"userpictureurl"];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"userpictureurl"];
    }
}

#pragma mark - messages handler

- (BOOL)isAttachment:(MXEvent*)message {
    if (message.eventType == MXEventTypeRoomMessage) {
        NSString *msgtype = message.content[@"msgtype"];
        if ([msgtype isEqualToString:kMXMessageTypeImage]
            || [msgtype isEqualToString:kMXMessageTypeAudio]
            || [msgtype isEqualToString:kMXMessageTypeVideo]
            || [msgtype isEqualToString:kMXMessageTypeLocation]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isNotification:(MXEvent*)message {
    // We consider as notification mxEvent which is not a text message or an attachment
    if (message.eventType == MXEventTypeRoomMessage) {
        NSString *msgtype = message.content[@"msgtype"];
        if ([msgtype isEqualToString:kMXMessageTypeEmote]) {
            return YES;
        }
        return NO;
    }
    return YES;
}

- (NSString*)displayTextFor:(MXEvent*)message inSubtitleMode:(BOOL)isSubtitle {
    NSString *displayText = nil;
    // Retrieve roomData related to the message
    MXRoomData *roomData = [self.mxData getRoomData:message.room_id];
    // Prepare display name for concerned users
    NSString *memberDisplayName = [roomData memberName:message.user_id];
    NSString *targetDisplayName = nil;
    if (message.state_key) {
        targetDisplayName = [roomData memberName:message.state_key];
    }
    
    switch (message.eventType) {
        case MXEventTypeRoomName: {
            displayText = [NSString stringWithFormat:@"%@ changed the room name to: %@", memberDisplayName, message.content[@"name"]];
            break;
        }
        case MXEventTypeRoomTopic: {
            displayText = [NSString stringWithFormat:@"%@ changed the topic to: %@", memberDisplayName, message.content[@"topic"]];
            break;
        }
        case MXEventTypeRoomMember: {
            
            // Could be a membership change, display name change, etc.
            // Presently only membership change and display name change are expected
            
            // Check whether this is a displayname change
            if (message.prev_content) {
                NSString *prevDisplayname =  message.prev_content[@"displayname"];
                NSString *displayname = message.content[@"displayname"];
                if (prevDisplayname && displayname && [displayname isEqualToString:prevDisplayname] == NO) {
                    displayText = [NSString stringWithFormat:@"%@ changed their display name from %@ to %@", message.user_id, prevDisplayname, displayname];
                }
            }
            
            if (displayText == nil) {
                // Consider here a membership change by default
                NSString* membership = message.content[@"membership"];
                
                if ([membership isEqualToString:@"invite"]) {
                    displayText = [NSString stringWithFormat:@"%@ invited %@", memberDisplayName, targetDisplayName];
                } else if ([membership isEqualToString:@"join"]) {
                    displayText = [NSString stringWithFormat:@"%@ joined", memberDisplayName];
                } else if ([membership isEqualToString:@"leave"]) {
                    if ([message.user_id isEqualToString:message.state_key]) {
                        displayText = [NSString stringWithFormat:@"%@ left", memberDisplayName];
                    } else {
                        if (message.prev_content) {
                            NSString *prev = message.prev_content[@"membership"];
                            
                            if ([prev isEqualToString:@"join"] || [prev isEqualToString:@"invite"]) {
                                displayText = [NSString stringWithFormat:@"%@ kicked %@", memberDisplayName, targetDisplayName];
                                if (message.content[@"reason"]) {
                                    displayText = [NSString stringWithFormat:@"%@: %@", displayText, message.content[@"reason"]];
                                }
                            } else if ([prev isEqualToString:@"ban"]) {
                                displayText = [NSString stringWithFormat:@"%@ unbanned %@", memberDisplayName, targetDisplayName];
                            }
                        }
                    }
                } else if ([membership isEqualToString:@"ban"]) {
                    displayText = [NSString stringWithFormat:@"%@ banned %@", memberDisplayName, targetDisplayName];
                    if (message.content[@"reason"]) {
                        displayText = [NSString stringWithFormat:@"%@: %@", displayText, message.content[@"reason"]];
                    }
                }
            }
            break;
        }
        case MXEventTypeRoomCreate: {
            NSString *creatorId = message.content[@"creator"];
            if (creatorId) {
                displayText = [NSString stringWithFormat:@"%@ created the room", [roomData memberName:creatorId]];
            }
            break;
        }
        case MXEventTypeRoomJoinRules: {
            NSString *joinRule = message.content[@"join_rule"];
            if (joinRule) {
                displayText = [NSString stringWithFormat:@"The join rule is: %@", joinRule];
            }
            break;
        }
        case MXEventTypeRoomPowerLevels: {
            displayText = @"The power level of room members are:";
            for (NSString *key in message.content.allKeys) {
                displayText = [NSString stringWithFormat:@"%@\r\n%@:%@", displayText, key, [message.content objectForKey:key]];
            }
            break;
        }
        case MXEventTypeRoomAddStateLevel: {
            NSString *minLevel = message.content[@"level"];
            if (minLevel) {
                displayText = [NSString stringWithFormat:@"The minimum power level a user needs to add state is: %@", minLevel];
            }
            break;
        }
        case MXEventTypeRoomSendEventLevel: {
            NSString *minLevel = message.content[@"level"];
            if (minLevel) {
                displayText = [NSString stringWithFormat:@"The minimum power level a user needs to send an event is: %@", minLevel];
            }
            break;
        }
        case MXEventTypeRoomOpsLevel: {
            displayText = @"The minimum power levels that a user must have before acting are:";
            for (NSString *key in message.content.allKeys) {
                displayText = [NSString stringWithFormat:@"%@\r\n%@:%@", displayText, key, [message.content objectForKey:key]];
            }
            break;
        }
        case MXEventTypeRoomAliases: {
            NSArray *aliases = message.content[@"aliases"];
            if (aliases) {
                displayText = [NSString stringWithFormat:@"The room aliases are: %@", aliases];
            }
            break;
        }
        case MXEventTypeRoomMessage: {
            NSString *msgtype = message.content[@"msgtype"];
            if ([msgtype isEqualToString:kMXMessageTypeText]) {
                displayText = message.content[@"body"];
            } else if ([msgtype isEqualToString:kMXMessageTypeEmote]) {
                displayText = [NSString stringWithFormat:@"* %@ %@", memberDisplayName, message.content[@"body"]];
            } else if ([msgtype isEqualToString:kMXMessageTypeImage]) {
                displayText = @"image attachment";
            } else if ([msgtype isEqualToString:kMXMessageTypeAudio]) {
                displayText = @"audio attachment";
            } else if ([msgtype isEqualToString:kMXMessageTypeVideo]) {
                displayText = @"video attachment";
            } else if ([msgtype isEqualToString:kMXMessageTypeLocation]) {
                displayText = @"location attachment";
            }
            
            // Check whether the sender name has to be added
            if (isSubtitle && [msgtype isEqualToString:kMXMessageTypeEmote] == NO) {
                displayText = [NSString stringWithFormat:@"%@: %@", memberDisplayName, displayText];
            }
            
            break;
        }
        case MXEventTypeRoomMessageFeedback: {
            NSString *type = message.content[@"type"];
            NSString *eventId = message.content[@"target_event_id"];
            if (type && eventId) {
                displayText = [NSString stringWithFormat:@"Feedback event (id: %@): %@", eventId, type];
            }
            break;
        }
        case MXEventTypeCustom:
            break;
        default:
            break;
    }
    
    if (displayText == nil) {
        NSLog(@"ERROR: Unsupported message %@)", message.description);
        if (isSubtitle) {
            displayText = @"";
        } else {
            displayText = [NSString stringWithFormat:@"%@%@", kMatrixHandlerUnsupportedMessagePrefix, message.description];
        }
    }
    
    return displayText;
}

@end
