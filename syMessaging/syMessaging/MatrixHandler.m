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

static MatrixHandler *sharedHandler = nil;

@interface MatrixHandler ()

@property (nonatomic,readwrite) BOOL isInitialSyncDone;

@end

@implementation MatrixHandler

@synthesize homeServerURL, homeServer, userLogin, userId, accessToken;

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
        
        // Read potential homeserver url in shared defaults object
        if (self.homeServerURL) {
            self.mxHomeServer = [[MXHomeServer alloc] initWithHomeServer:self.homeServerURL];
            
            if (self.accessToken) {
                [self openSession];
            }
        }
    }
    return self;
}

- (void)openSession {
    self.mxSession = [[MXSession alloc] initWithHomeServer:self.homeServerURL userId:self.userId accessToken:self.accessToken];
    if (self.mxSession) {
        self.mxData = [[MXData alloc] initWithMatrixSession:self.mxSession];
        [self.mxData start:^{
            self.isInitialSyncDone = YES;
        } failure:^(NSError *error) {
            NSLog(@"Initial Sync failed: %@", error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
    }
}

- (void)closeSession {
    [self.mxData close];
    self.mxData = nil;
    [self.mxSession close];
    self.mxSession = nil;
    self.isInitialSyncDone = NO;
}

- (void)dealloc {
    [self closeSession];
    self.mxHomeServer = nil;
}

#pragma mark -

- (BOOL)isLogged {
    return (self.accessToken != nil);
}

- (void)logout {
    // Reset access token (mxSession is closed by setter)
    self.accessToken = nil;
}

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

#pragma mark - messages handler

- (BOOL)isAttachment:(MXEvent*)message {
    if (message.eventType == MXEventTypeRoomMessage) {
        NSString *msgtype = message.content[@"msgtype"];
        if ([msgtype isEqualToString:@"m.image"]
            || [msgtype isEqualToString:@"m.audio"]
            || [msgtype isEqualToString:@"m.video"]
            || [msgtype isEqualToString:@"m.location"]) {
            return YES;
        }
    }
    return NO;
}

- (NSString*)displayTextFor:(MXEvent*)message inDetailMode:(BOOL)isDetailMode {
    NSString *displayText = nil;
    // Retrieve roomData related to the message
    MXRoomData *roomData = [self.mxData getRoomData:message.room_id];
    // Prepare display name for concerned users
    NSString *userDisplayName = [self displayNameFor:[roomData getMember:message.user_id]];
    NSString *targetDisplayName = nil;
    if (message.state_key) {
        targetDisplayName = [self displayNameFor:[roomData getMember:message.state_key]];
    }
    
    switch (message.eventType) {
        case MXEventTypeRoomName: {
            displayText = [NSString stringWithFormat:@"%@ changed the room name to: %@", userDisplayName, message.content[@"name"]];
            break;
        }
        case MXEventTypeRoomTopic: {
            displayText = [NSString stringWithFormat:@"%@ changed the topic to: %@", userDisplayName, message.content[@"topic"]];
            break;
        }
        case MXEventTypeRoomMember: {
            NSString* membership = message.content[@"membership"];
            
            if ([membership isEqualToString:@"invite"]) {
                displayText = [NSString stringWithFormat:@"%@ invited %@", userDisplayName, targetDisplayName];
            } else if ([membership isEqualToString:@"join"]) {
                displayText = [NSString stringWithFormat:@"%@ joined", userDisplayName];
            } else if ([membership isEqualToString:@"leave"]) {
                if ([message.user_id isEqualToString:message.state_key]) {
                    displayText = [NSString stringWithFormat:@"%@ left", userDisplayName];
                } else {
                    NSString *prev = message.content[@"prev"];
                    
                    if ([prev isEqualToString:@"join"] || [prev isEqualToString:@"invite"]) {
                        displayText = [NSString stringWithFormat:@"%@ kicked %@", userDisplayName, targetDisplayName];
                        if (message.content[@"reason"]) {
                            displayText = [NSString stringWithFormat:@"%@: %@", displayText, message.content[@"reason"]];
                        }
                    } else if ([prev isEqualToString:@"ban"]) {
                        displayText = [NSString stringWithFormat:@"%@ unbanned %@", userDisplayName, targetDisplayName];
                    }
                }
            } else if ([membership isEqualToString:@"ban"]) {
                displayText = [NSString stringWithFormat:@"%@ banned %@", userDisplayName, targetDisplayName];
                if (message.content[@"reason"]) {
                    displayText = [NSString stringWithFormat:@"%@: %@", displayText, message.content[@"reason"]];
                }
            }
            break;
        }
            //        case MXEventTypeRoomCreate:
            //            break;
            //        case MXEventTypeRoomJoinRules:
            //            break;
            //        case MXEventTypeRoomPowerLevels:
            //            break;
            //        case MXEventTypeRoomAddStateLevel:
            //            break;
            //        case MXEventTypeRoomSendEventLevel:
            //            break;
            //        case MXEventTypeRoomOpsLevel:
            //            break;
            //        case MXEventTypeRoomAliases:
            //            break;
        case MXEventTypeRoomMessage: {
            NSString *msgtype = message.content[@"msgtype"];
            if ([msgtype isEqualToString:@"m.text"]) {
                displayText = message.content[@"body"];
            } else if ([msgtype isEqualToString:@"m.emote"]) {
                displayText = [NSString stringWithFormat:@"* %@ %@", userDisplayName, message.content[@"body"]];
            } else if ([msgtype isEqualToString:@"m.image"]) {
                displayText = @"image attachment";
            } else if ([msgtype isEqualToString:@"m.audio"]) {
                displayText = @"audio attachment";
            } else if ([msgtype isEqualToString:@"m.video"]) {
                displayText = @"video attachment";
            } else if ([msgtype isEqualToString:@"m.location"]) {
                displayText = @"location attachment";
            }
            
            // Check whether the sender name has to be added
            if (isDetailMode && [msgtype isEqualToString:@"m.emote"] == NO) {
                displayText = [NSString stringWithFormat:@"%@: %@", userDisplayName, displayText];
            }
            
            break;
        }
            //        case MXEventTypeRoomMessageFeedback:
            //            break;
            //        case MXEventTypeCustom:
            //            break;
        default:
            break;
    }
    
    if (displayText == nil) {
        NSLog(@"ERROR: Unsupported message %@)", message.description);
        displayText = @"";
    }
    
    return displayText;
}


- (NSString*)displayNameFor:(MXRoomMember*)member {
    // Check whether a display name is available. If none, use the user id
    if (member.displayname.length) {
        return member.displayname;
    }
    return member.user_id;
}

@end
