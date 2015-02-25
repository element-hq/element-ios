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

#import "AppDelegate.h"
#import "APNSHandler.h"
#import "AppSettings.h"
#import "RoomViewController.h"
#import "MatrixSDKHandler.h"
#import "MediaManager.h"
#import "SettingsViewController.h"
#import "ContactManager.h"
#import "RageShakableUIResponder.h"

#import "AFNetworkReachabilityManager.h"

#define MAKE_STRING(x) #x
#define MAKE_NS_STRING(x) @MAKE_STRING(x)

@interface AppDelegate () <UISplitViewControllerDelegate> {
    // Reachability observer
    id reachabilityObserver;
}

@end

@implementation AppDelegate

#pragma mark -

+ (AppDelegate*)theDelegate {
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

#pragma mark -

- (NSString*)appVersion {
    if (!_appVersion) {
        _appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    }
    
    return _appVersion;
}

- (NSString*)build {
    if (!_build) {
        NSString *buildBranch = nil;
        NSString *buildNumber = nil;
        // Check whether GIT_BRANCH and BUILD_NUMBER were provided during compilation in command line argument.
#ifdef GIT_BRANCH
        buildBranch = MAKE_NS_STRING(GIT_BRANCH);
#endif
#ifdef BUILD_NUMBER
        buildNumber = [NSString stringWithFormat:@"#%d", BUILD_NUMBER];
#endif
        if (buildBranch && buildNumber) {
            _build = [NSString stringWithFormat:@"%@ %@", buildBranch, buildNumber];
        } else if (buildNumber){
            _build = buildNumber;
        } else {
            _build = buildBranch ? buildBranch : @"(no build info)";
        }
    }
    return _build;
}

- (void)setIsOffline:(BOOL)isOffline {
    if (isOffline) {
        // Add observer to leave this state automatically.
        reachabilityObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AFNetworkingReachabilityDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            NSNumber *statusItem = note.userInfo[AFNetworkingReachabilityNotificationStatusItem];
            if (statusItem) {
                AFNetworkReachabilityStatus reachabilityStatus = statusItem.integerValue;
                if (reachabilityStatus == AFNetworkReachabilityStatusReachableViaWiFi || reachabilityStatus == AFNetworkReachabilityStatusReachableViaWWAN) {
                    self.isOffline = NO;
                }
            }
        }];
    } else {
        // Release potential observer
        if (reachabilityObserver) {
            [[NSNotificationCenter defaultCenter] removeObserver:reachabilityObserver];
            reachabilityObserver = nil;
        }
    }
    
    _isOffline = isOffline;
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    if ([self.window.rootViewController isKindOfClass:[MasterTabBarController class]])
    {
        self.masterTabBarController = (MasterTabBarController*)self.window.rootViewController;
        self.masterTabBarController.delegate = self;
        
        // By default the "Home" tab is focussed
        [self.masterTabBarController setSelectedIndex:TABBAR_HOME_INDEX];
        
        UIViewController* recents = [self.masterTabBarController.viewControllers objectAtIndex:TABBAR_RECENTS_INDEX];
        if ([recents isKindOfClass:[UISplitViewController class]]) {
            UISplitViewController *splitViewController = (UISplitViewController *)recents;
            UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
            
            // IOS >= 8
            if ([splitViewController respondsToSelector:@selector(displayModeButtonItem)]) {
                navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
                
                // on IOS 8 iPad devices, force to display the primary and the secondary viewcontroller
                // to avoid empty room View Controller in portrait orientation
                // else, the user cannot select a room
                // shouldHideViewController delegate method is also implemented
                if ([splitViewController respondsToSelector:@selector(preferredDisplayMode)] && [(NSString*)[UIDevice currentDevice].model hasPrefix:@"iPad"]) {
                    splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
                }
            }
            
            splitViewController.delegate = self;
        } else {
            // Patch missing image in tabBarItem for iOS < 8.0
            recents.tabBarItem.image = [[UIImage imageNamed:@"tab_recents"] imageWithRenderingMode:UIImageRenderingModeAutomatic];
        }
        
        _isAppForeground = NO;
        
        // Retrieve custom configuration
        NSString* userDefaults = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UserDefaults"];
        NSString *defaultsPathFromApp = [[NSBundle mainBundle] pathForResource:userDefaults ofType:@"plist"];
        NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPathFromApp];
        [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if ([MatrixSDKHandler sharedHandler].status != MatrixSDKHandlerStatusLoggedOut) {
            [self registerUserNotificationSettings];
            // When user is already logged, we launch the app on Recents
            [self.masterTabBarController setSelectedIndex:TABBAR_RECENTS_INDEX];
        }
    }

    // clear the notifications counter
    [self clearNotifications];

    // check if the app crashed last time
    if ([MXLogger crashLog]) {
        [RageShakableUIResponder reportCrash:self.masterTabBarController.selectedViewController];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    if (self.errorNotification) {
        [self.errorNotification dismiss:NO];
        self.errorNotification = nil;
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    // Stop reachability monitoring
    self.isOffline = NO;
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
    
    // check if some media msut be released to reduce the cache size
    [MediaManager reduceCacheSizeToInsert:0];
    // Suspend Matrix handler
    [[MatrixSDKHandler sharedHandler] pauseInBackgroundTask];
    
    // clear the notifications counter
    [self clearNotifications];
    
    _isAppForeground = NO;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    // clear the notifications counter
    [self clearNotifications];
    
    _isAppForeground = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    // Start monitoring reachability
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    // Resume Matrix handler
    [[MatrixSDKHandler sharedHandler] resume];
    
    // refresh the contacts list
    [[ContactManager sharedManager] fullRefresh];
    
    _isAppForeground = YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - APNS methods

- (void)registerUserNotificationSettings {
    NSLog(@"[AppDelegate] Attempting to get push token...");
    if (!isAPNSRegistered) {
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            // Registration on iOS 8 and later
            UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
                                                                                                 |UIRemoteNotificationTypeSound
                                                                                                 |UIRemoteNotificationTypeAlert) categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        } else {
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationType)(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge)];
        }
    }
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication*)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
    NSLog(@"[AppDelegate] Got APNS token!");
    
    APNSHandler* apnsHandler = [APNSHandler sharedHandler];
    [apnsHandler setDeviceToken:deviceToken];
    
    // force send the push token once per app start
    if (!isAPNSRegistered) {
        apnsHandler.isActive = YES;
    }
    isAPNSRegistered = YES;
}

- (void)application:(UIApplication*)app didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
    NSLog(@"[AppDelegate] Failed to register for APNS: %@", error);
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
#ifdef DEBUG
    // log the full userInfo only in DEBUG
    NSLog(@"[AppDelegate] APNS: %@", userInfo);
#endif
    
    completionHandler(UIBackgroundFetchResultNoData);
    
    // Jump to the concerned room only if the app is transitioning from the background
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive) {
        // Look for the room id
        NSString* roomId = [userInfo objectForKey:@"room_id"];
        if (roomId.length) {
            [self.masterTabBarController showRoom:roomId];
        }
    }
}

#pragma mark -

- (void)logout {
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    [[APNSHandler sharedHandler] reset];
    isAPNSRegistered = NO;
    // Clear cache
    [MediaManager clearCache];
    // Logout Matrix
    [[MatrixSDKHandler sharedHandler] logout];
    [self.masterTabBarController showAuthenticationScreen];
    // Reset App settings
    [[AppSettings sharedSettings] reset];
    //  reset the contact manager
    [[ContactManager sharedManager] reset];
    // By default the "Home" tab is focussed
    [self.masterTabBarController setSelectedIndex:TABBAR_HOME_INDEX];
}

- (MXCAlert*)showErrorAsAlert:(NSError*)error {
    // Ignore network reachability error when the app is already offline
    if (self.isOffline && [error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorNotConnectedToInternet) {
        return nil;
    }
    
    if (self.errorNotification) {
        [self.errorNotification dismiss:NO];
    }
    
    NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
    if (!title)
    {
        title = @"Error";
    }
    NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    
    self.errorNotification = [[MXCAlert alloc] initWithTitle:title message:msg style:MXCAlertStyleAlert];
    self.errorNotification.cancelButtonIndex = [self.errorNotification addActionWithTitle:@"OK" style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
        [AppDelegate theDelegate].errorNotification = nil;
    }];
    [self.errorNotification showInViewController:[self.masterTabBarController selectedViewController]];
    
    // Switch in offline mode in case of network reachability error
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorNotConnectedToInternet) {
        self.isOffline = YES;
    }
    
    return self.errorNotification;
}

- (void)clearNotifications
{
    // force to clear the notification center
    // switching from 0 -> 1 -> 0 seems forcing the notifications center to refresh
    // so resetting it does not clear the notifications center.
    [UIApplication sharedApplication].applicationIconBadgeNumber = 1;
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

#pragma mark - SplitViewController delegate

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[RoomViewController class]] && ([(RoomViewController *)[(UINavigationController *)secondaryViewController topViewController] roomId] == nil)) {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation {
    // oniPad devices, force to display the primary and the secondary viewcontroller
    // to avoid empty room View Controller in portrait orientation
    // else, the user cannot select a room
    return NO;
}

#pragma mark - UITabBarControllerDelegate delegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    BOOL res = YES;
    
    if (tabBarController.selectedIndex == TABBAR_SETTINGS_INDEX) {
        // Prompt user to save unsaved profile changes before switching to another tab
        UIViewController* selectedViewController = [tabBarController selectedViewController];
        if ([selectedViewController isKindOfClass:[UINavigationController class]]) {
            UIViewController *topViewController = ((UINavigationController*)selectedViewController).topViewController;
            if ([topViewController isKindOfClass:[SettingsViewController class]]) {
                res = [((SettingsViewController *)topViewController) shouldLeave:^() {
                    // This block is called when tab change is delayed to prompt user about his profile changes
                    NSUInteger nextSelectedViewController = [tabBarController.viewControllers indexOfObject:viewController];
                    tabBarController.selectedIndex = nextSelectedViewController;
                }];
            }
        }
    }    
    return res;
}

@end
