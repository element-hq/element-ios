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

@synthesize homeServerURL, userLogin, userId, accessToken;

+ (id)sharedHandler {
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
        
        // Read potential homeserver in shared defaults object
        if (self.homeServerURL) {
            self.homeServer = [[MXHomeServer alloc] initWithHomeServer:self.homeServerURL];
            
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
    self.homeServer = nil;
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
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"homeserver"];
}

- (void)setHomeServerURL:(NSString *)inHomeserver {
    if (inHomeserver.length) {
        [[NSUserDefaults standardUserDefaults] setObject:inHomeserver forKey:@"homeserver"];
        self.homeServer = [[MXHomeServer alloc] initWithHomeServer:self.homeServerURL];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"homeserver"];
        self.homeServer = nil;
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

- (NSString*)getMessageDisplayText:(MXEvent*)message {
    NSString *displayText = nil;
    
    switch (message.eventType) {
        case MXEventTypeRoomName:
            displayText = [NSString stringWithFormat:@"%@ changed the room name to: %@", message.user_id, message.content[@"name"]];
            break;
        case MXEventTypeRoomTopic:
            displayText = [NSString stringWithFormat:@"%@ changed the topic to: %@", message.user_id, message.content[@"topic"]];
            break;
        case MXEventTypeRoomMember: {
            NSString* membership = message.content[@"membership"];
            
            if ([membership isEqualToString:@"invite"]) {
                displayText = [NSString stringWithFormat:@"%@ invited %@", message.user_id, message.state_key];
            } else if ([membership isEqualToString:@"join"]) {
                displayText = [NSString stringWithFormat:@"%@ joined", message.state_key];
            } else if ([membership isEqualToString:@"leave"]) {
                if ([message.user_id isEqualToString:message.state_key]) {
                    displayText = [NSString stringWithFormat:@"%@ left", message.state_key];
                } else {
                    NSString *prev = message.content[@"prev"];
                    
                    if ([prev isEqualToString:@"join"] || [prev isEqualToString:@"invite"]) {
                        displayText = [NSString stringWithFormat:@"%@ kicked %@", message.user_id, message.state_key];
                        if (message.content[@"reason"]) {
                            displayText = [NSString stringWithFormat:@"%@: %@", displayText, message.content[@"reason"]];
                        }
                    } else if ([prev isEqualToString:@"ban"]) {
                        displayText = [NSString stringWithFormat:@"%@ unbanned %@", message.user_id, message.state_key];
                    }
                }
            } else if ([membership isEqualToString:@"ban"]) {
                displayText = [NSString stringWithFormat:@"%@ banned %@", message.user_id, message.state_key];
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
                displayText = [NSString stringWithFormat:@"* %@ %@", message.user_id, message.content[@"body"]];
            } else if ([msgtype isEqualToString:@"m.image"]) {
                displayText = @"image attachment";
            } else if ([msgtype isEqualToString:@"m.audio"]) {
                displayText = @"audio attachment";
            } else if ([msgtype isEqualToString:@"m.video"]) {
                displayText = @"video attachment";
            } else if ([msgtype isEqualToString:@"m.location"]) {
                displayText = @"location attachment";
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

@end
