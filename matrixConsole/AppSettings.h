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

@interface AppSettings : NSObject

@property (nonatomic) BOOL enableInAppNotifications;

@property (nonatomic) BOOL displayAllEvents;
@property (nonatomic) BOOL hideRedactions;
@property (nonatomic) BOOL hideUnsupportedEvents;
@property (nonatomic) BOOL sortMembersUsingLastSeenTime;
@property (nonatomic) BOOL displayLeftUsers;

// return YES if the user got an alertView to allow or not the local contacts sync
@property (nonatomic, readonly) BOOL requestedLocalContactsSync;
// return YES if the user allows the local contacts sync
@property (nonatomic) BOOL syncLocalContacts;
// phonebook country code
@property (nonatomic) NSString* countryCode;

// cache sizes in bytes
@property (nonatomic) NSInteger currentMaxMediaCacheSize;
@property (nonatomic, readonly) NSInteger maxAllowedMediaCacheSize;


+ (AppSettings *)sharedSettings;

- (void)reset;

@end
