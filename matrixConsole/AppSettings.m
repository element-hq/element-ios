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
#import "MatrixHandler.h"

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
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"hideUnsupportedMessages"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"sortMembersUsingLastSeenTime"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"displayLeftUsers"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -

- (BOOL)enableInAppNotifications {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"enableInAppNotifications"];
}

- (void)setEnableInAppNotifications:(BOOL)notifications {
    [[MatrixHandler sharedHandler] enableInAppNotifications:notifications];
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
    [[MatrixHandler sharedHandler] forceInitialSync:NO];
}

- (BOOL)hideUnsupportedMessages {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"hideUnsupportedMessages"];
}

- (void)setHideUnsupportedMessages:(BOOL)hideUnsupportedMessages {
    [[NSUserDefaults standardUserDefaults] setBool:hideUnsupportedMessages forKey:@"hideUnsupportedMessages"];
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

@end
