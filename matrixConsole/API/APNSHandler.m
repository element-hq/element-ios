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
#import <MatrixKit/MatrixKit.h>

#import "APNSHandler.h"
#import "AppDelegate.h"

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
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"apnsIsActive"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"apnsDeviceToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];
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
    if (![MXKAccountManager sharedManager].accounts.count) {
        NSLog(@"[APNSHandler] Not setting push token because we're not logged in");
        return;
    }
    
    transientActivity = isActive;
    
#ifdef DEBUG
    NSString *appId = @"org.matrix.console.ios.dev";
#else
    NSString *appId = @"org.matrix.console.ios.prod";
#endif
    
    NSString *b64Token = [self.deviceToken base64EncodedStringWithOptions:0];
    NSDictionary *pushData = @{
                               @"url": @"https://matrix.org/_matrix/push/v1/notify",
                              };
    
    NSString *deviceLang = [NSLocale preferredLanguages][0];
    
    NSString * profileTag = [[NSUserDefaults standardUserDefaults] valueForKey:@"pusherProfileTag"];
    if (!profileTag) {
        profileTag = @"";
        NSString *alphabet = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        for (int i = 0; i < 16; ++i) {
            unsigned char c = [alphabet characterAtIndex:arc4random() % alphabet.length];
            profileTag = [profileTag stringByAppendingFormat:@"%c", c];
        }
        NSLog(@"[APNSHandler] Generated fresh profile tag: %@", profileTag);
        [[NSUserDefaults standardUserDefaults] setValue:profileTag forKey:@"pusherProfileTag"];
    } else {
        NSLog(@"[APNSHandler] Using existing profile tag: %@", profileTag);
    }
    
    NSObject *kind = isActive ? @"http" : [NSNull null];
    
    // Handle multi-session here
    NSArray *mxAccounts = [MXKAccountManager sharedManager].accounts;
    BOOL append = NO;
    for (MXKAccount *account in mxAccounts) {
        MXRestClient *restCli = account.mxRestClient;
        
        [restCli setPusherWithPushkey:b64Token kind:kind appId:appId appDisplayName:@"Matrix Console iOS" deviceDisplayName:[[UIDevice currentDevice] name] profileTag:profileTag lang:deviceLang data:pushData append:append success:^{
            [[NSUserDefaults standardUserDefaults] setBool:transientActivity forKey:@"apnsIsActive"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kAPNSHandlerHasBeenUpdated object:nil];
        } failure:^(NSError *error) {
            NSLog(@"[APNSHandler] Failed to send APNS token for %@! (%@)", account.mxCredentials.userId, error);
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kAPNSHandlerHasBeenUpdated object:nil];
        }];
        
        // Turn on 'append' flag to add another pusher with the given pushkey and App ID to any others user IDs
        append = YES;
    }
}

@end
