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

#import "APNSHandler.h"
#import "AppDelegate.h"
#import "MatrixHandler.h"

NSString *const kAPNSHandlerHasBeenUpdated = @"kAPNSHandlerHasBeenUpdated";

static APNSHandler *sharedHandler = nil;

@implementation APNSHandler

+ (APNSHandler *)sharedHandler {
    @synchronized(self) {
        if(sharedHandler == nil) {
            sharedHandler = [[super allocWithZone:NULL] init];
        }
    }
    return sharedHandler;
}

#pragma mark - reset

- (void)reset {
    self.isActive = NO;
    self.deviceToken = nil;
}

#pragma mark -

- (NSData *)deviceToken {
    NSData *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"apnsDeviceToken"];
    if (!token.length) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"apnsDeviceToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        token = nil;
    }
    return token;
}

- (void)setDeviceToken:(NSData *)deviceToken {
    NSData *oldToken = self.deviceToken;
    if (!deviceToken.length) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"apnsDeviceToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:@"apnsDeviceToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if (!oldToken) {
            // turn on the Apns flag, when the Apns registration succeeds for the first time
            self.isActive = YES;
        } else if (self.isActive && ![oldToken isEqualToData:deviceToken]) {
            // Resync APNS to on if we think APNS is on, but the token has changed
            self.isActive = YES;
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAPNSHandlerHasBeenUpdated object:nil];
}

- (BOOL)isAvailable {
    BOOL isRegisteredForRemoteNotifications = NO;
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
        // iOS 8 and later
        isRegisteredForRemoteNotifications = [[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
    } else {
        isRegisteredForRemoteNotifications = [[UIApplication sharedApplication] enabledRemoteNotificationTypes] != UIRemoteNotificationTypeNone;
    }
    return (isRegisteredForRemoteNotifications && self.deviceToken);
}

- (BOOL)isActive {
    return ([self isAvailable] && [[NSUserDefaults standardUserDefaults] boolForKey:@"apnsIsActive"]);
}

- (void)setIsActive:(BOOL)isActive {
    // Refuse to try & turn push on if we're not logged in, it's nonsensical.
    if (![[MatrixHandler sharedHandler] isLogged]) {
        NSLog(@"Not logged in: not setting push token because we're not logged in");
        return;
    }
    
    transientActivity = isActive;
    // FIXME send the device token to the server (in order to submit this token to the APS servers when the server sends a notification to the user)
    // Write transientActivity in standardUserDefaults forKey:@"apnsIsActive" on success
//    [[NSUserDefaults standardUserDefaults] setBool:transientActivity forKey:@"apnsIsActive"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAPNSHandlerHasBeenUpdated object:nil];
}

@end
