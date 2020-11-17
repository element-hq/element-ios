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

#import "Riot-Swift.h"


NSString *const AnalyticsNoficationsCategory = @"notifications";
NSString *const AnalyticsNoficationsTimeToDisplayContent = @"timelineDisplay";


// Duration data will be visible under the Piwik category called "Performance".
// Other values will be visible in "Metrics".
// Some Matomo screenshots are available at https://github.com/vector-im/element-ios/pull/3789.
NSString *const kAnalyticsPerformanceCategory = @"Performance";
NSString *const kAnalyticsMetricsCategory = @"Metrics";


@import MatomoTracker;

@interface Analytics ()
{
    MatomoTracker *matomoTracker;
}

@end

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

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        matomoTracker = [[MatomoTracker alloc] initWithSiteId:BuildSettings.analyticsAppId
                                                      baseURL:BuildSettings.analyticsServerUrl
                                                    userAgent:@"iOSMatomoTracker"];
        [self migrateFromFourPointFourSharedInstance];
    }
    return self;
}

- (void)migrateFromFourPointFourSharedInstance
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"migratedFromFourPointFourSharedInstance"]) return;
    [matomoTracker copyFromOldSharedInstance];
    [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"migratedFromFourPointFourSharedInstance"];
}

- (void)start
{
    // Check whether the user has enabled the sending of crash reports.
    if (RiotSettings.shared.enableCrashReport)
    {
        matomoTracker.isOptedOut = NO;

        [matomoTracker setCustomVariableWithIndex:1 name:@"App Platform" value:@"iOS Platform"];
        [matomoTracker setCustomVariableWithIndex:2 name:@"App Version" value:[AppDelegate theDelegate].appVersion];

        // The language is either the one selected by the user within the app
        // or, else, the one configured by the OS
        NSString *language = [NSBundle mxk_language] ? [NSBundle mxk_language] : [[NSBundle mainBundle] preferredLocalizations][0];
        [matomoTracker setCustomVariableWithIndex:4 name:@"Chosen Language" value:language];

        MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        if (account)
        {
            [matomoTracker setCustomVariableWithIndex:7 name:@"Homeserver URL" value:account.mxCredentials.homeServer];
            [matomoTracker setCustomVariableWithIndex:8 name:@"Identity Server URL" value:account.identityServerURL];
        }

        // TODO: We should also track device and os version
        // But that needs to be decided for all platforms

        // Catch and log crashes
        [MXLogger logCrashes:YES];
        [MXLogger setBuildVersion:[AppDelegate theDelegate].build];

#ifdef DEBUG
        // Disable analytics in debug as it pollutes stats
        matomoTracker.isOptedOut = YES;
#endif
    }
    else
    {
        NSLog(@"[AppDelegate] The user decided to not send analytics");
        matomoTracker.isOptedOut = YES;
        [MXLogger logCrashes:NO];
    }
}

- (void)stop
{
    matomoTracker.isOptedOut = YES;
    [MXLogger logCrashes:NO];
}

- (void)trackScreen:(NSString *)screenName
{
    // Use the same pattern as Android
    NSString *appName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
    NSString *appVersion = [AppDelegate theDelegate].appVersion;

    [matomoTracker trackWithView:@[@"ios", appName, appVersion, screenName]
                                     url:nil];
}

- (void)dispatch
{
    [matomoTracker dispatch];
}

#pragma mark - MXAnalyticsDelegate

- (void)trackDuration:(NSTimeInterval)seconds category:(NSString*)category name:(NSString*)name
{
    // Report time in ms to make figures look better in Matomo
    NSNumber *value = @(seconds * 1000);
    [matomoTracker trackWithEventWithCategory:kAnalyticsPerformanceCategory
                                       action:category
                                         name:name
                                       number:value
                                          url:nil];
}

- (void)trackValue:(NSNumber*)value category:(NSString*)category name:(NSString*)name
{
    [matomoTracker trackWithEventWithCategory:kAnalyticsMetricsCategory
                                       action:category
                                         name:name
                                       number:value
                                          url:nil];
}

@end
