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
    id userUpdateListener;
    // Handle events notification
    id eventsListener;
}

@property (nonatomic,readwrite) BOOL isInitialSyncDone;
@property (nonatomic,readwrite) BOOL isResumeDone;
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
        _isResumeDone = NO;
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

        // Use MXMemoryStore as MXStore to not loose message
        MXMemoryStore *store = [[MXMemoryStore alloc] init];
        
        self.mxSession = [[MXSession alloc] initWithMatrixRestClient:self.mxRestClient andStore:store];
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
                                             kMXEventTypeStringRoomMessageFeedback
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

        // Launch mxSession
        [self.mxSession start:^{
            self.isInitialSyncDone = YES;
            _isResumeDone = YES;
            
            // Register listener to update user's information
            userUpdateListener = [self.mxSession.myUser listenToUserUpdate:^(MXEvent *event) {
                // Update local storage
                if (![self.userDisplayName isEqualToString:event.content[@"displayname"]]) {
                    self.userDisplayName = event.content[@"displayname"];
                }
                if (![self.userPictureURL isEqualToString:event.content[@"avatar_url"]]) {
                    self.userPictureURL = event.content[@"avatar_url"];
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
    
    self.isInitialSyncDone = NO;
    _isResumeDone = NO;
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

- (void)pause {
    if (self.mxSession) {
        [self.mxSession pause];
        self.isResumeDone = NO;
    }
}

- (void)resume {
    if (self.mxSession) {
        [self.mxSession resume:^{
            self.isResumeDone = YES;
        }];
    }
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
        eventsListener = [self.mxSession listenToEventsOfTypes:self.eventsFilterForMessages onEvent:^(MXEvent *event, MXEventDirection direction, id customObject) {
            // Consider only live event
            if (direction == MXEventDirectionForwards) {
                MXRoomState* roomState = (MXRoomState*)customObject;
                // If we are running on background, show a local notif
                if (UIApplicationStateBackground == [UIApplication sharedApplication].applicationState)
                {
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
                    localNotification.hasAction = YES;
                    [localNotification setAlertBody:[self displayTextForEvent:event withRoomState:roomState inSubtitleMode:YES]];
                    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                } else if (![event.userId isEqualToString:self.userId]
                           && ![[AppDelegate theDelegate].masterTabBarController.visibleRoomId isEqualToString:event.roomId]) {
                    // The sender is not the user and the concerned room is not presently visible,
                    // we display a notification by removing existing one (if any)
                    if (self.mxNotification) {
                        [self.mxNotification dismiss:NO];
                    }
                    
                    self.mxNotification = [[CustomAlert alloc] initWithTitle:roomState.displayname
                                                                     message:[self displayTextForEvent:event withRoomState:roomState inSubtitleMode:YES]
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


- (NSString*)displayTextForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState inSubtitleMode:(BOOL)isSubtitle {
    NSString *displayText = nil;
    // Prepare display name for concerned users
    NSString *memberDisplayName = [roomState memberName:event.userId];
    NSString *targetDisplayName = nil;
    if (event.stateKey) {
        targetDisplayName = [roomState memberName:event.stateKey];
    }
    
    switch (event.eventType) {
        case MXEventTypeRoomName: {
            displayText = [NSString stringWithFormat:@"%@ changed the room name to: %@", memberDisplayName, event.content[@"name"]];
            break;
        }
        case MXEventTypeRoomTopic: {
            displayText = [NSString stringWithFormat:@"%@ changed the topic to: %@", memberDisplayName, event.content[@"topic"]];
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
            
            // Check whether the membership is unchanged
            if (prevMembership && membership && [membership isEqualToString:prevMembership]) {
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
                    displayText = [NSString stringWithFormat:@"%@ changed their display name from %@ to %@", event.userId, prevDisplayname, displayname];
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
                    if ([event.userId isEqualToString:event.stateKey]) {
                        displayText = [NSString stringWithFormat:@"%@ left", memberDisplayName];
                    } else if (prevMembership) {
                        if ([prevMembership isEqualToString:@"join"] || [prevMembership isEqualToString:@"invite"]) {
                            displayText = [NSString stringWithFormat:@"%@ kicked %@", memberDisplayName, targetDisplayName];
                            if (event.content[@"reason"]) {
                                displayText = [NSString stringWithFormat:@"%@: %@", displayText, event.content[@"reason"]];
                            }
                        } else if ([prevMembership isEqualToString:@"ban"]) {
                            displayText = [NSString stringWithFormat:@"%@ unbanned %@", memberDisplayName, targetDisplayName];
                        }
                    }
                } else if ([membership isEqualToString:@"ban"]) {
                    displayText = [NSString stringWithFormat:@"%@ banned %@", memberDisplayName, targetDisplayName];
                    if (event.content[@"reason"]) {
                        displayText = [NSString stringWithFormat:@"%@: %@", displayText, event.content[@"reason"]];
                    }
                }
            }
            break;
        }
        case MXEventTypeRoomCreate: {
            NSString *creatorId = event.content[@"creator"];
            if (creatorId) {
                displayText = [NSString stringWithFormat:@"%@ created the room", [roomState memberName:creatorId]];
            }
            break;
        }
        case MXEventTypeRoomJoinRules: {
            NSString *joinRule = event.content[@"join_rule"];
            if (joinRule) {
                displayText = [NSString stringWithFormat:@"The join rule is: %@", joinRule];
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
            break;
        }
        case MXEventTypeRoomAliases: {
            NSArray *aliases = event.content[@"aliases"];
            if (aliases) {
                displayText = [NSString stringWithFormat:@"The room aliases are: %@", aliases];
            }
            break;
        }
        case MXEventTypeRoomMessage: {
            NSString *msgtype = event.content[@"msgtype"];
            displayText = [event.content[@"body"] isKindOfClass:[NSString class]] ? event.content[@"body"] : nil;
            
            if ([msgtype isEqualToString:kMXMessageTypeEmote]) {
                displayText = [NSString stringWithFormat:@"* %@ %@", memberDisplayName, displayText];
            } else if ([msgtype isEqualToString:kMXMessageTypeImage]) {
                displayText = displayText? displayText : @"image attachment";
                // Check attachment validity
                if (![self isSupportedAttachment:event]) {
                    NSLog(@"ERROR: Unsupported attachment %@", event.description);
                    // Check whether unsupported/unexpected messages should be exposed
                    if (isSubtitle || [AppSettings sharedSettings].hideUnsupportedMessages) {
                        displayText = @"invalid image attachment";
                    } else {
                        // Display event content as unsupported message
                        displayText = [NSString stringWithFormat:@"%@%@", kMatrixHandlerUnsupportedMessagePrefix, event.description];
                    }
                }
            } else if ([msgtype isEqualToString:kMXMessageTypeAudio]) {
                displayText = displayText? displayText : @"audio attachment";
                if (![self isSupportedAttachment:event]) {
                    NSLog(@"ERROR: Unsupported attachment %@", event.description);
                    if (isSubtitle || [AppSettings sharedSettings].hideUnsupportedMessages) {
                        displayText = @"invalid audio attachment";
                    } else {
                        displayText = [NSString stringWithFormat:@"%@%@", kMatrixHandlerUnsupportedMessagePrefix, event.description];
                    }
                }
            } else if ([msgtype isEqualToString:kMXMessageTypeVideo]) {
                displayText = displayText? displayText : @"video attachment";
                if (![self isSupportedAttachment:event]) {
                    NSLog(@"ERROR: Unsupported attachment %@", event.description);
                    if (isSubtitle || [AppSettings sharedSettings].hideUnsupportedMessages) {
                        displayText = @"invalid video attachment";
                    } else {
                        displayText = [NSString stringWithFormat:@"%@%@", kMatrixHandlerUnsupportedMessagePrefix, event.description];
                    }
                }
            } else if ([msgtype isEqualToString:kMXMessageTypeLocation]) {
                displayText = displayText? displayText : @"location attachment";
                if (![self isSupportedAttachment:event]) {
                    NSLog(@"ERROR: Unsupported attachment %@", event.description);
                    if (isSubtitle || [AppSettings sharedSettings].hideUnsupportedMessages) {
                        displayText = @"invalid location attachment";
                    } else {
                        displayText = [NSString stringWithFormat:@"%@%@", kMatrixHandlerUnsupportedMessagePrefix, event.description];
                    }
                }
            }
            
            // Check whether the sender name has to be added
            if (isSubtitle && [msgtype isEqualToString:kMXMessageTypeEmote] == NO) {
                displayText = [NSString stringWithFormat:@"%@: %@", memberDisplayName, displayText];
            }
            
            break;
        }
        case MXEventTypeRoomMessageFeedback: {
            NSString *type = event.content[@"type"];
            NSString *eventId = event.content[@"target_event_id"];
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
    
    if (!displayText) {
        NSLog(@"ERROR: Unsupported event %@)", event.description);
        if (!isSubtitle && ![AppSettings sharedSettings].hideUnsupportedMessages) {
            // Return event content as unsupported event
            displayText = [NSString stringWithFormat:@"%@%@", kMatrixHandlerUnsupportedMessagePrefix, event.description];
        }
    }
    
    return displayText;
}

@end
