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
            self.mxRestClient = [[MXRestClient alloc] initWithHomeServer:self.homeServerURL];
            
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
    
    MXCredentials *credentials = [[MXCredentials alloc] initWithHomeServer:self.homeServerURL
                                                                    userId:self.userId
                                                               accessToken:self.accessToken];
    
    self.mxRestClient = [[MXRestClient alloc] initWithCredentials:credentials];
    if (self.mxRestClient) {
        // Request user's display name
        [self.mxRestClient displayNameForUser:self.userId success:^(NSString *displayname) {
            self.userDisplayName = displayname;
        } failure:^(NSError *error) {
            NSLog(@"Get displayName failed: %@", error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
        // Request user's avatar
        [self.mxRestClient avatarUrlForUser:self.userId success:^(NSString *avatar_url) {
            self.userPictureURL = avatar_url;
        } failure:^(NSError *error) {
            NSLog(@"Get picture url failed: %@", error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
        
        self.mxSession = [[MXSession alloc] initWithMatrixRestClient:self.mxRestClient];
        // Check here whether the app user wants to display all the events
        if ([[AppSettings sharedSettings] displayAllEvents]) {
            // Override events filter to retrieve all the events
            self.mxSession.eventsFilterForMessages = @[
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
        // Launch mxSession
        [self.mxSession start:^{
            self.isInitialSyncDone = YES;
            
            // Register listener to update user's information
            roomMembersListener = [self.mxSession listenToEventsOfTypes:@[kMXEventTypeStringPresence] onEvent:^(MXEvent *event, MXEventDirection direction, id customObject) {
                // Consider only live events
                if (direction == MXEventDirectionForwards) {
                    // Consider only events from app user
                    if ([event.userId isEqualToString:self.userId]) {
                        // Update local storage
                        if (![self.userDisplayName isEqualToString:event.content[@"displayname"]]) {
                            self.userDisplayName = event.content[@"displayname"];
                        }
                        if (![self.userPictureURL isEqualToString:event.content[@"avatar_url"]]) {
                            self.userPictureURL = event.content[@"avatar_url"];
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
        [self.mxSession removeListener:eventsListener];
        eventsListener = nil;
    }
    if (roomMembersListener) {
        [self.mxSession removeListener:roomMembersListener];
        roomMembersListener = nil;
    }
    [self.mxSession close];
    self.mxSession = nil;
    
    [self.mxRestClient close];
    if (self.homeServerURL) {
        self.mxRestClient = [[MXRestClient alloc] initWithHomeServer:self.homeServerURL];
    } else {
        self.mxRestClient = nil;
    }
    
    self.isInitialSyncDone = NO;
    notifyOpenSessionFailure = YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
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
    if (self.accessToken) {
        [self openSession];
    }
}

- (void)enableEventsNotifications:(BOOL)isEnabled {
    if (isEnabled) {
        // Register events listener
        eventsListener = [self.mxSession listenToEventsOfTypes:self.mxSession.eventsFilterForMessages onEvent:^(MXEvent *event, MXEventDirection direction, id customObject) {
            // Consider only live event (Ignore presence event)
            if (direction == MXEventDirectionForwards && (event.eventType != MXEventTypePresence)) {
                // If we are running on background, show a local notif
                if (UIApplicationStateBackground == [UIApplication sharedApplication].applicationState)
                {
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
                    localNotification.hasAction = YES;
                    [localNotification setAlertBody:[self displayTextFor:event inSubtitleMode:YES]];
                    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                } else if ([[AppDelegate theDelegate].masterTabBarController.visibleRoomId isEqualToString:event.roomId] == NO) {
                    // The concerned room is not presently visible, we display a notification by removing existing one (if any)
                    if (self.mxNotification) {
                        [self.mxNotification dismiss:NO];
                    }
                    
                    self.mxNotification = [[CustomAlert alloc] initWithTitle:[self.mxSession room:event.roomId].state.displayname
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
                                                        [[AppDelegate theDelegate].masterTabBarController showRoom:event.roomId];
                                                    }];
                    
                    [self.mxNotification showInViewController:[[AppDelegate theDelegate].masterTabBarController selectedViewController]];
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
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"userid"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
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
    [[NSUserDefaults standardUserDefaults] synchronize];
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
    [[NSUserDefaults standardUserDefaults] synchronize];
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
    [[NSUserDefaults standardUserDefaults] synchronize];
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
    MXRoom *room = [self.mxSession room:message.roomId];
    // Prepare display name for concerned users
    NSString *memberDisplayName = [room.state memberName:message.userId];
    NSString *targetDisplayName = nil;
    if (message.stateKey) {
        targetDisplayName = [room.state memberName:message.stateKey];
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
            // Presently only change on membership, display name and avatar are supported
            
            // Retrieve membership
            NSString* membership = message.content[@"membership"];
            NSString *prevMembership = nil;
            if (message.prevContent) {
                prevMembership = message.prevContent[@"membership"];
            }
            
            // Check whether the membership is unchanged
            if (prevMembership && membership && [membership isEqualToString:prevMembership]) {
                // Check whether the display name has been changed
                NSString *displayname = message.content[@"displayname"];
                NSString *prevDisplayname =  message.prevContent[@"displayname"];
                if (!displayname.length) {
                    displayname = nil;
                }
                if (!prevDisplayname.length) {
                    prevDisplayname = nil;
                }
                if ((displayname || prevDisplayname) && ([displayname isEqualToString:prevDisplayname] == NO)) {
                    displayText = [NSString stringWithFormat:@"%@ changed their display name from %@ to %@", message.userId, prevDisplayname, displayname];
                }
                
                // Check whether the avatar has been changed
                NSString *avatar = message.content[@"avatar_url"];
                NSString *prevAvatar = message.prevContent[@"avatar_url"];
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
                        displayText = [NSString stringWithFormat:@"%@ changed their picture profile", memberDisplayName];
                    }
                }
            } else {
                // Consider here a membership change
                if ([membership isEqualToString:@"invite"]) {
                    displayText = [NSString stringWithFormat:@"%@ invited %@", memberDisplayName, targetDisplayName];
                } else if ([membership isEqualToString:@"join"]) {
                    displayText = [NSString stringWithFormat:@"%@ joined", memberDisplayName];
                } else if ([membership isEqualToString:@"leave"]) {
                    if ([message.userId isEqualToString:message.stateKey]) {
                        displayText = [NSString stringWithFormat:@"%@ left", memberDisplayName];
                    } else if (prevMembership) {
                        if ([prevMembership isEqualToString:@"join"] || [prevMembership isEqualToString:@"invite"]) {
                            displayText = [NSString stringWithFormat:@"%@ kicked %@", memberDisplayName, targetDisplayName];
                            if (message.content[@"reason"]) {
                                displayText = [NSString stringWithFormat:@"%@: %@", displayText, message.content[@"reason"]];
                            }
                        } else if ([prevMembership isEqualToString:@"ban"]) {
                            displayText = [NSString stringWithFormat:@"%@ unbanned %@", memberDisplayName, targetDisplayName];
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
                displayText = [NSString stringWithFormat:@"%@ created the room", [room.state memberName:creatorId]];
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
            NSDictionary *users = message.content[@"users"];
            for (NSString *key in users.allKeys) {
                displayText = [NSString stringWithFormat:@"%@\r\n\u2022 %@: %@", displayText, key, [users objectForKey:key]];
            }
            if (message.content[@"users_default"]) {
                displayText = [NSString stringWithFormat:@"%@\r\n\u2022 %@: %@", displayText, @"default", message.content[@"users_default"]];
            }
            
            displayText = [NSString stringWithFormat:@"%@\r\nThe minimum power levels that a user must have before acting are:", displayText];
            if (message.content[@"ban"]) {
                displayText = [NSString stringWithFormat:@"%@\r\n\u2022 ban: %@", displayText, message.content[@"ban"]];
            }
            if (message.content[@"kick"]) {
                displayText = [NSString stringWithFormat:@"%@\r\n\u2022 kick: %@", displayText, message.content[@"kick"]];
            }
            if (message.content[@"redact"]) {
                displayText = [NSString stringWithFormat:@"%@\r\n\u2022 redact: %@", displayText, message.content[@"redact"]];
            }
            
            displayText = [NSString stringWithFormat:@"%@\r\nThe minimum power levels related to events are:", displayText];
            NSDictionary *events = message.content[@"events"];
            for (NSString *key in events.allKeys) {
                displayText = [NSString stringWithFormat:@"%@\r\n\u2022 %@: %@", displayText, key, [events objectForKey:key]];
            }
            if (message.content[@"events_default"]) {
                displayText = [NSString stringWithFormat:@"%@\r\n\u2022 %@: %@", displayText, @"events_default", message.content[@"events_default"]];
            }
            if (message.content[@"state_default"]) {
                displayText = [NSString stringWithFormat:@"%@\r\n\u2022 %@: %@", displayText, @"state_default", message.content[@"state_default"]];
            }
            break;
        }
//        case MXEventTypeRoomAddStateLevel: {
//            NSString *minLevel = message.content[@"level"];
//            if (minLevel) {
//                displayText = [NSString stringWithFormat:@"The minimum power level a user needs to add state is: %@", minLevel];
//            }
//            break;
//        }
//        case MXEventTypeRoomSendEventLevel: {
//            NSString *minLevel = message.content[@"level"];
//            if (minLevel) {
//                displayText = [NSString stringWithFormat:@"The minimum power level a user needs to send an event is: %@", minLevel];
//            }
//            break;
//        }
//        case MXEventTypeRoomOpsLevel: {
//            displayText = @"The minimum power levels that a user must have before acting are:";
//            for (NSString *key in message.content.allKeys) {
//                displayText = [NSString stringWithFormat:@"%@\r\n%@:%@", displayText, key, [message.content objectForKey:key]];
//            }
//            break;
//        }
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
        if (isSubtitle || [AppSettings sharedSettings].hideUnsupportedMessages) {
            displayText = @"";
        } else {
            // Return event content as unsupported message
            displayText = [NSString stringWithFormat:@"%@%@", kMatrixHandlerUnsupportedMessagePrefix, message.description];
        }
    }
    
    return displayText;
}

@end
