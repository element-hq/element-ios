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

#import <UIKit/UIKit.h>

extern NSString *const kAPNSHandlerHasBeenUpdated;

@interface APNSHandler : NSObject {
    BOOL transientActivity;
}

@property (nonatomic, copy) NSData *deviceToken;
@property (nonatomic) BOOL isAvailable; // true when app is registered for remote notif, and devive token is known
@property (nonatomic) BOOL isActive; // true when APNS is turned on (locally available and synced with server)

+ (APNSHandler *)sharedHandler;

- (void)reset;

@end
