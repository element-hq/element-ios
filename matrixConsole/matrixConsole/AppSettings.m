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

#import "AppSettings.h"
#import "MatrixSDKHandler.h"

static AppSettings *sharedSettings = nil;

@implementation AppSettings

+ (AppSettings *)sharedSettings {
    @synchronized(self) {
        if(sharedSettings == nil)
        {
            sharedSettings = [[super allocWithZone:NULL] init];
        }
    }
    return sharedSettings;
}

#pragma  mark - 

-(AppSettings *)init {
    if (self = [super init]) {
    }
    return self;
}

- (void)dealloc {
}

- (void)reset {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"enableInAppNotifications"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"specificWordsToAlertOn"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"displayAllEvents"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"hideRedactedInformation"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"hideUnsupportedEvents"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"sortMembersUsingLastSeenTime"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"displayLeftUsers"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"maxMediaCacheSize"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"syncLocalContacts"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -

- (BOOL)enableInAppNotifications {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"enableInAppNotifications"];
}

- (void)setEnableInAppNotifications:(BOOL)notifications {
    [[MatrixSDKHandler sharedHandler] enableInAppNotifications:notifications];
    [[NSUserDefaults standardUserDefaults] setBool:notifications forKey:@"enableInAppNotifications"];
}

- (NSArray*)specificWordsToAlertOn {
    NSArray* res = [[NSUserDefaults standardUserDefaults] objectForKey:@"specificWordsToAlertOn"];
    
    // avoid returning nil
    if (!res) {
        res = [[NSArray alloc] init];
    }
    
    return res;
}

- (void)setSpecificWordsToAlertOn:(NSArray*)words {
    
    if (!words.count) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"specificWordsToAlertOn"];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:words forKey:@"specificWordsToAlertOn"];
    }
}

- (BOOL)displayAllEvents {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"displayAllEvents"];
}

- (void)setDisplayAllEvents:(BOOL)displayAllEvents {
    [[NSUserDefaults standardUserDefaults] setBool:displayAllEvents forKey:@"displayAllEvents"];
    // Flush and restore Matrix data
    [[MatrixSDKHandler sharedHandler] forceInitialSync:NO];
}

- (BOOL)hideRedactedInformation {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"hideRedactedInformation"];
}

- (void)setHideRedactedInformation:(BOOL)hideRedactedInformation {
    [[NSUserDefaults standardUserDefaults] setBool:hideRedactedInformation forKey:@"hideRedactedInformation"];
}

- (BOOL)hideUnsupportedEvents {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"hideUnsupportedEvents"];
}

- (void)setHideUnsupportedEvents:(BOOL)hideUnsupportedEvents {
    [[NSUserDefaults standardUserDefaults] setBool:hideUnsupportedEvents forKey:@"hideUnsupportedEvents"];
}

- (BOOL)sortMembersUsingLastSeenTime {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"sortMembersUsingLastSeenTime"];
}

- (void)setSortMembersUsingLastSeenTime:(BOOL)sortMembersUsingLastSeen {
    [[NSUserDefaults standardUserDefaults] setBool:sortMembersUsingLastSeen forKey:@"sortMembersUsingLastSeenTime"];
}

- (BOOL)displayLeftUsers {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"displayLeftUsers"];
}

- (void)setDisplayLeftUsers:(BOOL)displayLeftUsers {
    [[NSUserDefaults standardUserDefaults] setBool:displayLeftUsers forKey:@"displayLeftUsers"];
}


- (BOOL)requestedLocalContactsSync {
    id val = [[NSUserDefaults standardUserDefaults] valueForKey:@"syncLocalContacts"];
    
    // the value has never been set
    if (!val) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"syncLocalContacts"];
    }
    
    return (nil != val);
}

- (BOOL)syncLocalContacts {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"syncLocalContacts"];
}

- (void)setSyncLocalContacts:(BOOL)syncLocalContacts {
    [[NSUserDefaults standardUserDefaults] setBool:syncLocalContacts forKey:@"syncLocalContacts"];
}

- (NSInteger)maxAllowedMediaCacheSize {
    return 1024 * 1024 * 1024;
}

- (NSInteger)currentMaxMediaCacheSize {
    
    NSInteger res = [[NSUserDefaults standardUserDefaults] integerForKey:@"maxMediaCacheSize"];
    
    // no default value, assume that 1 GB is enough
    if (res == 0) {
        res = [AppSettings sharedSettings].maxAllowedMediaCacheSize;
    }
    
    return res;
}

- (void)setCurrentMaxMediaCacheSize:(NSInteger)aMaxCacheSize {
    if ((aMaxCacheSize == 0) && (aMaxCacheSize > [AppSettings sharedSettings].maxAllowedMediaCacheSize)) {
        aMaxCacheSize = [AppSettings sharedSettings].maxAllowedMediaCacheSize;
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:aMaxCacheSize forKey:@"maxMediaCacheSize"];
}

@end
