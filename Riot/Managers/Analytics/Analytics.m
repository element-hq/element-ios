/*
 Copyright 2018 New Vector Ltd

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

#import "Analytics.h"

#import "AppDelegate.h"
#import "Riot-Swift.h"

// All metrics are store under a Piwik category called "Metrics".
// Then, there are 2 Piwik actions: "iOS.startup" and "iOS.stats" (these actions
// are namespaced by plaform to have a nice rendering on the Piwik website).
// Then, we use constants defined by the Matrix SDK as Piwik Names (ex:"mountData")
NSString *const kAnalyticsMetricsCategory = @"Metrics";
NSString *const kAnalyticsMetricsActionPattern = @"iOS.%@";

// E2E telemetry is stored under a Piwik category called "E2E".
NSString *const kAnalyticsE2eCategory = @"E2E";
NSString *const kAnalyticsE2eDecryptionFailureAction = @"Decryption failure";


@import PiwikTracker;

@implementation Analytics

+ (instancetype)sharedInstance
{
    static Analytics *sharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[Analytics alloc] init];
    });

    return sharedInstance;
}

- (void)start
{
    NSDictionary *piwikConfig = [[NSUserDefaults standardUserDefaults] objectForKey:@"piwik"];
    [PiwikTracker configureSharedInstanceWithSiteID:piwikConfig[@"siteId"]
                                            baseURL:[NSURL URLWithString:piwikConfig[@"url"]]
                                          userAgent:@"iOSPiwikTracker"];

    // Check whether the user has enabled the sending of crash reports.
    if (RiotSettings.shared.enableCrashReport)
    {
        [PiwikTracker shared].isOptedOut = NO;

        [[PiwikTracker shared] setCustomVariableWithIndex:1 name:@"App Platform" value:@"iOS Platform"];
        [[PiwikTracker shared] setCustomVariableWithIndex:2 name:@"App Version" value:[AppDelegate theDelegate].appVersion];

        // The language is either the one selected by the user within the app
        // or, else, the one configured by the OS
        NSString *language = [NSBundle mxk_language] ? [NSBundle mxk_language] : [[NSBundle mainBundle] preferredLocalizations][0];
        [[PiwikTracker shared] setCustomVariableWithIndex:4 name:@"Chosen Language" value:language];

        MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        if (account)
        {
            [[PiwikTracker shared] setCustomVariableWithIndex:7 name:@"Homeserver URL" value:account.mxCredentials.homeServer];
            [[PiwikTracker shared] setCustomVariableWithIndex:8 name:@"Identity Server URL" value:account.identityServerURL];
        }

        // TODO: We should also track device and os version
        // But that needs to be decided for all platforms

        // Catch and log crashes
        [MXLogger logCrashes:YES];
        [MXLogger setBuildVersion:[AppDelegate theDelegate].build];

#ifdef DEBUG
        // Disable analytics in debug as it pollutes stats
        [PiwikTracker shared].isOptedOut = YES;
#endif
    }
    else
    {
        NSLog(@"[AppDelegate] The user decided to not send analytics");
        [PiwikTracker shared].isOptedOut = YES;
        [MXLogger logCrashes:NO];
    }
}

- (void)stop
{
    [PiwikTracker shared].isOptedOut = YES;
    [MXLogger logCrashes:NO];
}

- (void)trackScreen:(NSString *)screenName
{
    // Use the same pattern as Android
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSString *appVersion = [AppDelegate theDelegate].appVersion;

    [[PiwikTracker shared] trackWithView:@[@"ios", appName, appVersion, screenName]
                                     url:nil];
}

- (void)dispatch
{
    [[PiwikTracker shared] dispatch];
}

- (void)trackLaunchScreenDisplayDuration:(NSTimeInterval)seconds
{
    NSString *action = [NSString stringWithFormat:kAnalyticsMetricsActionPattern, kMXAnalyticsStartupCategory];

    [[PiwikTracker shared] trackWithEventWithCategory:kAnalyticsMetricsCategory
                                               action:action
                                                 name:kMXAnalyticsStartupLaunchScreen
                                               number:@(seconds * 1000)
                                                  url:nil];
}

#pragma mark - MXAnalyticsDelegate

- (void)trackStartupStorePreloadDuration: (NSTimeInterval)seconds
{
    NSString *action = [NSString stringWithFormat:kAnalyticsMetricsActionPattern, kMXAnalyticsStartupCategory];

    [[PiwikTracker shared] trackWithEventWithCategory:kAnalyticsMetricsCategory
                                               action:action
                                                 name:kMXAnalyticsStartupStorePreload
                                               number:@(seconds * 1000)
                                                  url:nil];
}

- (void)trackStartupMountDataDuration: (NSTimeInterval)seconds
{
    NSString *action = [NSString stringWithFormat:kAnalyticsMetricsActionPattern, kMXAnalyticsStartupCategory];

    [[PiwikTracker shared] trackWithEventWithCategory:kAnalyticsMetricsCategory
                                               action:action
                                                 name:kMXAnalyticsStartupMountData
                                               number:@(seconds * 1000)
                                                  url:nil];
}

- (void)trackStartupSyncDuration: (NSTimeInterval)seconds isInitial: (BOOL)isInitial
{
    NSString *action = [NSString stringWithFormat:kAnalyticsMetricsActionPattern, kMXAnalyticsStartupCategory];

    [[PiwikTracker shared] trackWithEventWithCategory:kAnalyticsMetricsCategory
                                               action:action
                                                 name:isInitial ? kMXAnalyticsStartupInititialSync : kMXAnalyticsStartupIncrementalSync
                                               number:@(seconds * 1000)
                                                  url:nil];
}

- (void)trackRoomCount: (NSUInteger)roomCount
{
    NSString *action = [NSString stringWithFormat:kAnalyticsMetricsActionPattern, kMXAnalyticsStatsCategory];

    [[PiwikTracker shared] trackWithEventWithCategory:kAnalyticsMetricsCategory
                                               action:action
                                                 name:kMXAnalyticsStatsRooms
                                               number:@(roomCount)
                                                  url:nil];
}

#pragma mark - MXDecryptionFailureDelegate

- (void)trackFailures:(NSDictionary<NSString *,NSNumber *> *)failuresCounts
{
    for (NSString *reason in failuresCounts)
    {
        [[PiwikTracker shared] trackWithEventWithCategory:kAnalyticsE2eCategory
                                                   action:kAnalyticsE2eDecryptionFailureAction
                                                     name:reason
                                                   number:failuresCounts[reason]
                                                      url:nil];
    }
}

@end
