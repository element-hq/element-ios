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

#import "RecentsDataSource.h"
#import "RoomDataSource.h"

#import "EventFormatter.h"

#import "HomeViewController.h"
#import "RoomViewController.h"

#import "DirectoryViewController.h"
#import "SettingsViewController.h"
#import "ContactDetailsViewController.h"

#import "RageShakeManager.h"

#import "NSBundle+MatrixKit.h"
#import "MatrixSDK/MatrixSDK.h"

#import "Tools.h"

#import "AFNetworkReachabilityManager.h"

#import <AudioToolbox/AudioToolbox.h>

//#define MX_CALL_STACK_OPENWEBRTC
#ifdef MX_CALL_STACK_OPENWEBRTC
#import <MatrixOpenWebRTCWrapper/MatrixOpenWebRTCWrapper.h>
#endif

#ifdef MX_CALL_STACK_ENDPOINT
#import <MatrixEndpointWrapper/MatrixEndpointWrapper.h>
#endif

#include <MatrixSDK/MXJingleCallStack.h>

#import "VectorDesignValues.h"

#define MAKE_STRING(x) #x
#define MAKE_NS_STRING(x) @MAKE_STRING(x)

NSString *const kAppDelegateDidTapStatusBarNotification = @"kAppDelegateDidTapStatusBarNotification";

@interface AppDelegate ()
{
    /**
     Reachability observer
     */
    id reachabilityObserver;
    
    /**
     MatrixKit error observer
     */
    id matrixKitErrorObserver;
    
    /**
     matrix session observer used to detect new opened sessions.
     */
    id matrixSessionStateObserver;
    
    /**
     matrix account observers.
     */
    id addedAccountObserver;
    id removedAccountObserver;
    
    /**
     matrix call observer used to handle incoming/outgoing call.
     */
    id matrixCallObserver;
    
    /**
     The current call view controller (if any).
     */
    MXKCallViewController *currentCallViewController;
    
    /**
     Call status window displayed when user goes back to app during a call.
     */
    UIWindow* callStatusBarWindow;
    UIButton* callStatusBarButton;
    
    /**
     Account picker used in case of multiple account.
     */
    MXKAlert *accountPicker;
    
    /**
     Array of `MXSession` instances.
     */
    NSMutableArray *mxSessionArray;
    
    /**
     The room id of the current handled remote notification (if any)
     */
    NSString *remoteNotificationRoomId;

    /**
     The fragment of the universal link being processing.
     Only one fragment is handled at a time.
     */
    NSString *universalLinkFragmentPending;

    /**
     An universal link may need to wait for an account to be logged in or for a
     session to be running. Hence, this observer.
     */
    id universalLinkWaitingObserver;

    /**
     Suspend the error notifications when the navigation stack of the root view controller is updating.
     */
    BOOL isErrorNotificationSuspended;

    /**
     Completion block called when [self popToHomeViewControllerAnimated:] has been
     completed.
     */
    void (^popToHomeViewControllerCompletion)();

    /**
     The listeners to call events.
     There is one listener per MXSession.
     The key is an identifier of the MXSession. The value, the listener.
     */
    NSMutableDictionary *callEventsListeners;

    /**
     Currently displayed "Call not supported" alert.
     */
    MXKAlert *noCallSupportAlert;
}

@property (strong, nonatomic) MXKAlert *mxInAppNotification;

@end

@implementation AppDelegate

#pragma mark -

+ (AppDelegate*)theDelegate
{
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

#pragma mark -

- (NSString*)appVersion
{
    if (!_appVersion)
    {
        _appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    }
    
    return _appVersion;
}

- (NSString*)build
{
    if (!_build)
    {
        NSString *buildBranch = nil;
        NSString *buildNumber = nil;
        // Check whether GIT_BRANCH and BUILD_NUMBER were provided during compilation in command line argument.
#ifdef GIT_BRANCH
        buildBranch = MAKE_NS_STRING(GIT_BRANCH);
#endif
#ifdef BUILD_NUMBER
        buildNumber = [NSString stringWithFormat:@"#%d", BUILD_NUMBER];
#endif
        if (buildBranch && buildNumber)
        {
            _build = [NSString stringWithFormat:@"%@ %@", buildBranch, buildNumber];
        } else if (buildNumber){
            _build = buildNumber;
        } else
        {
            _build = buildBranch ? buildBranch : NSLocalizedStringFromTable(@"settings_config_no_build_info", @"Vector", nil);
        }
    }
    return _build;
}

- (void)setIsOffline:(BOOL)isOffline
{
    if (!reachabilityObserver)
    {
        // Define reachability observer when isOffline property is set for the first time
        reachabilityObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AFNetworkingReachabilityDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            
            NSNumber *statusItem = note.userInfo[AFNetworkingReachabilityNotificationStatusItem];
            if (statusItem)
            {
                AFNetworkReachabilityStatus reachabilityStatus = statusItem.integerValue;
                if (reachabilityStatus == AFNetworkReachabilityStatusNotReachable)
                {
                    [AppDelegate theDelegate].isOffline = YES;
                }
                else
                {
                    [AppDelegate theDelegate].isOffline = NO;
                }
            }
            
        }];
    }
    
    _isOffline = isOffline;
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifdef DEBUG
    // log the full launchOptions only in DEBUG
    NSLog(@"[AppDelegate] didFinishLaunchingWithOptions: %@", launchOptions);
#else
    NSLog(@"[AppDelegate] didFinishLaunchingWithOptions");
#endif
    
    // Override point for customization after application launch.
    
    // Define the navigation bar text color
    [[UINavigationBar appearance] setTintColor:kVectorColorGreen];
    
    // Customize the localized string table
    [NSBundle mxk_customizeLocalizedStringTableName:@"Vector"];
    
    mxSessionArray = [NSMutableArray array];
    callEventsListeners = [NSMutableDictionary dictionary];
    
    // To simplify navigation into the app, we retrieve here the navigation controller and the view controller related
    // to the Home screen ("Messages").
    // Note: UISplitViewController is not supported on iPhone for iOS < 8.0
    UIViewController* rootViewController = self.window.rootViewController;
    _homeNavigationController = nil;
    if ([rootViewController isKindOfClass:[UISplitViewController class]])
    {
        UISplitViewController *splitViewController = (UISplitViewController *)rootViewController;
        splitViewController.delegate = self;
        
        _homeNavigationController = [splitViewController.viewControllers objectAtIndex:0];
        
        if (splitViewController.viewControllers.count == 2)
        {
            UIViewController *detailsViewController = [splitViewController.viewControllers lastObject];
            
            if ([detailsViewController isKindOfClass:[UINavigationController class]])
            {
                _secondaryNavigationController = (UINavigationController*)detailsViewController;
                detailsViewController = _secondaryNavigationController.topViewController;
            }
            
            detailsViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
        }
        
        // on IOS 8 iPad devices, force to display the primary and the secondary viewcontroller
        // to avoid empty room View Controller in portrait orientation
        // else, the user cannot select a room
        // shouldHideViewController delegate method is also implemented
        if ([splitViewController respondsToSelector:@selector(preferredDisplayMode)] && [(NSString*)[UIDevice currentDevice].model hasPrefix:@"iPad"])
        {
            splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
        }
    }
    
    if (_homeNavigationController)
    {
        for (UIViewController *viewController in _homeNavigationController.viewControllers)
        {
            if ([viewController isKindOfClass:[HomeViewController class]])
            {
                _homeViewController = (HomeViewController*)viewController;
            }
        }
    }
    
    // Sanity check
    NSAssert(_homeViewController, @"Something wrong in Main.storyboard");
    
    _isAppForeground = NO;
    
    // Retrieve custom configuration
    NSString* userDefaults = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UserDefaults"];
    NSString *defaultsPathFromApp = [[NSBundle mainBundle] pathForResource:userDefaults ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPathFromApp];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Configure Google Analytics here if the option is enabled
    [self startGoogleAnalytics];
    
    // Add matrix observers, and initialize matrix sessions if the app is not launched in background.
    [self initMatrixSessions];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"[AppDelegate] applicationWillResignActive");
    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    // Release MatrixKit error observer
    if (matrixKitErrorObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:matrixKitErrorObserver];
        matrixKitErrorObserver = nil;
    }
    
    if (self.errorNotification)
    {
        [self.errorNotification dismiss:NO];
        self.errorNotification = nil;
    }
    
    if (accountPicker)
    {
        [accountPicker dismiss:NO];
        accountPicker = nil;
    }

    if (noCallSupportAlert)
    {
        [noCallSupportAlert dismiss:NO];
        noCallSupportAlert = nil;
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"[AppDelegate] applicationDidEnterBackground");
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    // Stop reachability monitoring
    if (reachabilityObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:reachabilityObserver];
        reachabilityObserver = nil;
    }
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:nil];
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
    _isOffline = NO;
    
    // check if some media must be released to reduce the cache size
    [MXKMediaManager reduceCacheSizeToInsert:0];
    
    // Hide potential notification
    if (self.mxInAppNotification)
    {
        [self.mxInAppNotification dismiss:NO];
        self.mxInAppNotification = nil;
    }

    // Discard any process on pending universal link
    [self resetPendingUniversalLink];
    
    // Suspend all running matrix sessions
    NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    for (MXKAccount *account in mxAccounts)
    {
        [account pauseInBackgroundTask];
    }
    
    // Refresh the notifications counter
    [self refreshApplicationIconBadgeNumber];
    
    _isAppForeground = NO;
    
    // GA: End a session while the app is in background
    [[[GAI sharedInstance] defaultTracker] set:kGAISessionControl value:@"end"];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"[AppDelegate] applicationWillEnterForeground");
    
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    // cancel any background sync before resuming
    // i.e. warn IOS that there is no new data with any received push.
    [self cancelBackgroundSync];
    
    // Open account session(s) if this is not already done (see [initMatrixSessions] in case of background launch).
    [[MXKAccountManager sharedManager] prepareSessionForActiveAccounts];
    
    _isAppForeground = YES;
    
    // GA: Start a new session. The next hit from this tracker will be the first in a new session.
    [[[GAI sharedInstance] defaultTracker] set:kGAISessionControl value:@"start"];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"[AppDelegate] applicationDidBecomeActive");
    
    remoteNotificationRoomId = nil;

    // Check if there is crash log to send
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enableCrashReport"])
    {
        [self checkExceptionToReport];
    }

    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    // Start monitoring reachability
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        // Check whether monitoring is ready
        if (status != AFNetworkReachabilityStatusUnknown)
        {
            if (status == AFNetworkReachabilityStatusNotReachable)
            {
                // Prompt user
                [[AppDelegate theDelegate] showErrorAsAlert:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:@{NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"network_offline_prompt", @"Vector", nil)}]];
            }
            else
            {
                self.isOffline = NO;
            }

            // Use a dispatch to avoid to kill ourselves
            dispatch_async(dispatch_get_main_queue(), ^{
                [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:nil];
            });
        }
        
    }];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    // Observe matrixKit error to alert user on error
    matrixKitErrorObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKErrorNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        [self showErrorAsAlert:note.object];
        
    }];
    
    // Resume all existing matrix sessions
    NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    for (MXKAccount *account in mxAccounts)
    {
        [account resume];
    }
    
    // refresh the contacts list
    [MXKContactManager sharedManager].enableFullMatrixIdSyncOnLocalContactsDidLoad = NO;
    [[MXKContactManager sharedManager] loadLocalContacts];
    
    _isAppForeground = YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"[AppDelegate] applicationWillTerminate");
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    [self stopGoogleAnalytics];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler
{
    BOOL continueUserActivity;

    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb])
    {
        continueUserActivity = [self handleUniversalLink:userActivity];
    }

    return continueUserActivity;
}

#pragma mark - Application layout handling

- (void)restoreInitialDisplay:(void (^)())completion
{
    // Suspend error notifications during navigation stack change.
    isErrorNotificationSuspended = YES;
    
    // Cancel search
    if (_homeViewController)
    {
        [_homeViewController hideSearch:NO];
    }
    
    // Dismiss potential view controllers that were presented modally (like the media picker).
    if (self.window.rootViewController.presentedViewController)
    {
        // Do it asynchronously to avoid hasardous dispatch_async after calling restoreInitialDisplay
        [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
            
            [self popToHomeViewControllerAnimated:NO completion:^{
                
                if (completion)
                {
                    completion();
                }
                
                // Restore noCallSupportAlert if any
                if (noCallSupportAlert)
                {
                    NSLog(@"[AppDelegate] restoreInitialDisplay: keep visible noCall support alert");
                    [noCallSupportAlert showInViewController:self.window.rootViewController];
                }
                
                // Enable error notification (Check whether a notification is pending)
                isErrorNotificationSuspended = NO;
                if (self.errorNotification)
                {
                    [self showErrorNotification];
                }
                
            }];
            
        }];
    }
    else
    {
        [self popToHomeViewControllerAnimated:NO completion:^{
            
            if (completion)
            {
                completion();
            }
            
            // Enable error notification (Check whether a notification is pending)
            isErrorNotificationSuspended = NO;
            if (self.errorNotification)
            {
                [self showErrorNotification];
            }
        }];
    }
}

- (MXKAlert*)showErrorAsAlert:(NSError*)error
{
    // Ignore fake error, or connection cancellation error
    if (!error || ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled))
    {
        return nil;
    }
    
    // Ignore network reachability error when the app is already offline
    if (self.isOffline && [error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorNotConnectedToInternet)
    {
        return nil;
    }
    
    if (self.errorNotification)
    {
        [self.errorNotification dismiss:NO];
    }
    
    NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
    NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    if (!title)
    {
        if (msg)
        {
            title = msg;
            msg = nil;
        }
        else
        {
            title = [NSBundle mxk_localizedStringForKey:@"error"];
        }
    }
    
    self.errorNotification = [[MXKAlert alloc] initWithTitle:title message:msg style:MXKAlertStyleAlert];
    self.errorNotification.cancelButtonIndex = [self.errorNotification addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                                                    [AppDelegate theDelegate].errorNotification = nil;
                                                }];
    
    // Display the error notification
    [self showErrorNotification];
    
    // Switch in offline mode in case of network reachability error
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorNotConnectedToInternet)
    {
        self.isOffline = YES;
    }
    
    return self.errorNotification;
}

- (void)showErrorNotification
{
    if (!isErrorNotificationSuspended)
    {
        if (self.window.rootViewController.presentedViewController)
        {
            [self.errorNotification showInViewController:self.window.rootViewController.presentedViewController];
        }
        else
        {
            [self.errorNotification showInViewController:self.window.rootViewController];
        }
    }
}

#pragma mark

- (void)popToHomeViewControllerAnimated:(BOOL)animated completion:(void (^)())completion
{
    // Force back to the main screen if this is the not the one that is displayed
    if (_homeViewController && _homeViewController != _homeNavigationController.visibleViewController)
    {
        // Listen to the homeNavigationController changes
        // We need to be sure that homeViewController is back to the screen
        popToHomeViewControllerCompletion = completion;
        _homeNavigationController.delegate = self;

        [_homeNavigationController popToViewController:_homeViewController animated:animated];
    }
    else
    {
        if (completion)
        {
            completion();
        }
    }
}

#pragma mark - UINavigationController delegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (viewController == _homeViewController)
    {
        _homeNavigationController.delegate = nil;
        
        // For unknown reason, the navigation bar is not restored correctly by [popToViewController:animated:]
        // when a ViewController has hidden it (see MXKAttachmentsViewController).
        // Patch: restore navigation bar by default here.
        _homeNavigationController.navigationBarHidden = NO;
        
        // Release the current selected room (if any).
        [_homeViewController closeSelectedRoom];
        
        if (popToHomeViewControllerCompletion)
        {
            void (^popToHomeViewControllerCompletion2)() = popToHomeViewControllerCompletion;
            popToHomeViewControllerCompletion = nil;

            // Dispatch the completion in order to let navigation stack refresh itself.
            dispatch_async(dispatch_get_main_queue(), ^{
                popToHomeViewControllerCompletion2();
            });
        }
    }
}

#pragma mark - Crash report handling

- (void)startGoogleAnalytics
{
    // Check whether the user has enabled the sending of crash reports.
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enableCrashReport"])
    {
        // Retrieve trackerId from GoogleService-Info.plist.
        NSString *googleServiceInfoPath = [[NSBundle mainBundle] pathForResource:@"GoogleService-Info" ofType:@"plist"];
        NSDictionary *googleServiceInfo = [NSDictionary dictionaryWithContentsOfFile:googleServiceInfoPath];
        NSString *gaTrackingID = [googleServiceInfo objectForKey:@"TRACKING_ID"];
        if (gaTrackingID)
        {
            // Catch and log crashes
            [MXLogger logCrashes:YES];
            [MXLogger setBuildVersion:[AppDelegate theDelegate].build];
            
            // Configure GAI options.
            GAI *gai = [GAI sharedInstance];
            
            // Disable GA UncaughtException: their crash reports are quite limited (100 first chars of the stack trace)
            // Let's MXLogger manage them
            gai.trackUncaughtExceptions = NO;
            
            // Initialize it with the app tracker ID
            [gai trackerWithTrackingId:gaTrackingID];
            
            // Set Google Analytics dispatch interval to e.g. 20 seconds.
            gai.dispatchInterval = 20;
        }
        else
        {
            NSLog(@"[AppDelegate] Unable to find tracker id for Google Analytics");
        }
    }
    else if ([[NSUserDefaults standardUserDefaults] objectForKey:@"enableCrashReport"])
    {
        NSLog(@"[AppDelegate] The user decides to do not use Google Analytics");
    }
}

- (void)stopGoogleAnalytics
{
    GAI *gai = [GAI sharedInstance];
    
    // End a session. The next hit from this tracker will be the last in the current session.
    [[gai defaultTracker] set:kGAISessionControl value:@"end"];
    
    // Flush pending GA messages
    [gai dispatch];
    
    [gai removeTrackerByName:[gai defaultTracker].name];
    
    [MXLogger logCrashes:NO];
}

// Check if there is a crash log to send to server
- (void)checkExceptionToReport
{
    // Check if the app crashed last time
    NSString *filePath = [MXLogger crashLog];
    if (filePath)
    {
        NSString *description = [[NSString alloc] initWithContentsOfFile:filePath
                                                            usedEncoding:nil
                                                                   error:nil];
        
        NSLog(@"[AppDelegate] Send crash log to Google Analytics:\n%@", description);
        
        // Send it via Google Analytics
        // The doc says the exception description must not exceeed 100 chars but it seems
        // to accept much more.
        // https://developers.google.com/analytics/devguides/collection/ios/v3/exceptions#overview
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker send:[[GAIDictionaryBuilder
                        createExceptionWithDescription:description
                        withFatal:[NSNumber numberWithBool:YES]] build]];
        [[GAI sharedInstance] dispatch];

        // Ask the user to send a crash report by email too
        // The email will provide logs and thus more context to the crash
        [[RageShakeManager sharedManager] promptCrashReportInViewController:self.window.rootViewController];
    }
}

#pragma mark - APNS methods

- (void)registerUserNotificationSettings
{
    if (!isAPNSRegistered)
    {
        // Registration on iOS 8 and later
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound |UIUserNotificationTypeAlert) categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication*)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    NSUInteger len = ((deviceToken.length > 8) ? 8 : deviceToken.length / 2);
    NSLog(@"[AppDelegate] Got APNS token! (%@ ...)", [deviceToken subdataWithRange:NSMakeRange(0, len)]);
    
    MXKAccountManager* accountManager = [MXKAccountManager sharedManager];
    [accountManager setApnsDeviceToken:deviceToken];
    
    isAPNSRegistered = YES;
}

- (void)application:(UIApplication*)app didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"[AppDelegate] Failed to register for APNS: %@", error);
}

- (void)cancelBackgroundSync
{
    if (_completionHandler)
    {
        _completionHandler(UIBackgroundFetchResultNoData);
        _completionHandler = nil;
    }
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
#ifdef DEBUG
    // log the full userInfo only in DEBUG
    NSLog(@"[AppDelegate] didReceiveRemoteNotification: %@", userInfo);
#else
    NSLog(@"[AppDelegate] didReceiveRemoteNotification");
#endif
    
    // Look for the room id
    NSString* roomId = [userInfo objectForKey:@"room_id"];
    if (roomId.length)
    {
        // TODO retrieve the right matrix session
        
        //**************
        // Patch consider the first session which knows the room id
        MXKAccount *dedicatedAccount = nil;
        
        NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
        
        if (mxAccounts.count == 1)
        {
            dedicatedAccount = mxAccounts.firstObject;
        }
        else
        {
            for (MXKAccount *account in mxAccounts)
            {
                if ([account.mxSession roomWithRoomId:roomId])
                {
                    dedicatedAccount = account;
                    break;
                }
            }
        }
        
        // sanity checks
        if (dedicatedAccount && dedicatedAccount.mxSession)
        {
            UIApplicationState state = [UIApplication sharedApplication].applicationState;
            
            // Jump to the concerned room only if the app is transitioning from the background
            if (state == UIApplicationStateInactive)
            {
                // Check whether another remote notification is not already processed
                if (!remoteNotificationRoomId)
                {
                    remoteNotificationRoomId = roomId;
                    
                    NSLog(@"[AppDelegate] didReceiveRemoteNotification: open the roomViewController %@", roomId);
                    
                    [self showRoom:roomId andEventId:nil withMatrixSession:dedicatedAccount.mxSession];
                }
                else
                {
                    NSLog(@"[AppDelegate] didReceiveRemoteNotification: busy");
                }
            }
            else if (!_completionHandler && (state == UIApplicationStateBackground))
            {
                _completionHandler = completionHandler;

                NSLog(@"[AppDelegate] didReceiveRemoteNotification: starts a background sync");
                
                [dedicatedAccount backgroundSync:20000 success:^{
                    NSLog(@"[AppDelegate] didReceiveRemoteNotification: the background sync succeeds");
                    
                    if (_completionHandler)
                    {
                        _completionHandler(UIBackgroundFetchResultNewData);
                        _completionHandler = nil;
                    }
                } failure:^(NSError *error) {
                    NSLog(@"[AppDelegate] didReceiveRemoteNotification: the background sync fails");
                    
                    if (_completionHandler)
                    {
                        _completionHandler(UIBackgroundFetchResultNoData);
                        _completionHandler = nil;
                    }
                }];
                
                // wait that the background sync is done
                return;
            }
        }
        else
        {
            NSLog(@"[AppDelegate] didReceiveRemoteNotification : no linked session / account has been found.");
        }
    }
    completionHandler(UIBackgroundFetchResultNoData);
}

- (void)refreshApplicationIconBadgeNumber
{
    NSUInteger count = [MXKRoomDataSourceManager missedDiscussionsCount];
    NSLog(@"[AppDelegate] refreshApplicationIconBadgeNumber: %tu", count);
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = count;
}

#pragma mark - Universal link

- (BOOL)handleUniversalLink:(NSUserActivity*)userActivity
{
    NSURL *webURL = userActivity.webpageURL;
    NSLog(@"[AppDelegate] handleUniversalLink: %@", webURL.absoluteString);

    // iOS Patch: fix vector.im urls before using it
    webURL = [Tools fixURLWithSeveralHashKeys:webURL];

    // Manage email validation link
    if ([webURL.path isEqualToString:@"/_matrix/identity/api/v1/validate/email/submitToken"])
    {
        // Validate the email on the passed identity server
        NSString *identityServer = [NSString stringWithFormat:@"%@://%@", webURL.scheme, webURL.host];
        MXRestClient *identityRestClient = [[MXRestClient alloc] initWithHomeServer:identityServer andOnUnrecognizedCertificateBlock:nil];

        // Extract required parameters from the link
        NSArray<NSString*> *pathParams;
        NSMutableDictionary *queryParams;
        [self parseUniversalLinkFragment:webURL.absoluteString outPathParams:&pathParams outQueryParams:&queryParams];

        [identityRestClient submitEmailValidationToken:queryParams[@"token"] clientSecret:queryParams[@"client_secret"] sid:queryParams[@"sid"] success:^{

            NSLog(@"[AppDelegate] handleUniversalLink. Email successfully validated.");

            if (queryParams[@"nextLink"])
            {
                // Continue the registration with the passed nextLink
                NSLog(@"[AppDelegate] handleUniversalLink. Complete registration with nextLink");
                NSURL *nextLink = [NSURL URLWithString:queryParams[@"nextLink"]];
                [self handleUniversalLinkFragment:nextLink.fragment];
            }
            else
            {
                // No nextLink in Vector world means validation for binding a new email
                NSLog(@"[AppDelegate] handleUniversalLink. TODO: Complete email binding");
            }

        } failure:^(NSError *error) {

            NSLog(@"[AppDelegate] handleUniversalLink. Error: submitToken failed: %@", error);
            [self showErrorAsAlert:error];

        }];

        return YES;
    }

    return [self handleUniversalLinkFragment:webURL.fragment];
}

- (BOOL)handleUniversalLinkFragment:(NSString*)fragment
{
    BOOL continueUserActivity = NO;
    MXKAccountManager *accountManager = [MXKAccountManager sharedManager];

    NSLog(@"[AppDelegate] Universal link: handleUniversalLinkFragment: %@", fragment);

    // The app manages only one universal link at a time
    // Discard any pending one
    [self resetPendingUniversalLink];

    // Extract params
    NSArray<NSString*> *pathParams;
    NSMutableDictionary *queryParams;
    [self parseUniversalLinkFragment:fragment outPathParams:&pathParams outQueryParams:&queryParams];

    // Sanity check
    if (!pathParams.count)
    {
        NSLog(@"[AppDelegate] Universal link: Error: No path parameters");
        return NO;
    }

    // Check the action to do
    if ([pathParams[0] isEqualToString:@"room"] && pathParams.count >= 2)
    {
        if (accountManager.activeAccounts.count)
        {
            // The link is the form of "/room/[roomIdOrAlias]" or "/room/[roomIdOrAlias]/[eventId]"
            NSString *roomIdOrAlias = pathParams[1];

            // Is it a link to an event of a room?
            NSString *eventId = (pathParams.count >= 3) ? pathParams[2] : nil;

            // Check there is an account that knows this room
            MXKAccount *account = [accountManager accountKnowingRoomWithRoomIdOrAlias:roomIdOrAlias];
            if (account)
            {
                NSString *roomId = roomIdOrAlias;

                // Translate the alias into the room id
                if ([roomIdOrAlias hasPrefix:@"#"])
                {
                    MXRoom *room = [account.mxSession roomWithAlias:roomIdOrAlias];
                    if (room)
                    {
                        roomId = room.roomId;
                    }
                }

                // Open the room page
                [self showRoom:roomId andEventId:eventId withMatrixSession:account.mxSession];

                continueUserActivity = YES;
            }
            else
            {
                // We will display something but we need to do some requests before.
                // So, come back to the home VC and show its loading wheel while processing
                [self restoreInitialDisplay:^{

                    [_homeViewController startActivityIndicator];

                    if ([roomIdOrAlias hasPrefix:@"#"])
                    {
                        // The alias may be not part of user's rooms states
                        // Ask the HS to resolve the room alias into a room id and then retry
                        universalLinkFragmentPending = fragment;
                        MXKAccount* account = accountManager.activeAccounts.firstObject;
                        [account.mxSession.matrixRestClient roomIDForRoomAlias:roomIdOrAlias success:^(NSString *roomId) {

                            // Note: the activity indicator will not disappear if the session is not ready
                            [_homeViewController stopActivityIndicator];

                            // Check that 'fragment' has not been cancelled
                            if ([universalLinkFragmentPending isEqualToString:fragment])
                            {
                                // Retry opening the link but with the returned room id
                                NSString *newUniversalLinkFragment =
                                [fragment stringByReplacingOccurrencesOfString:[roomIdOrAlias stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                                                    withString:[roomId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                                [self handleUniversalLinkFragment:newUniversalLinkFragment];
                            }

                        } failure:^(NSError *error) {
                            NSLog(@"[AppDelegate] Universal link: Error: The home server failed to resolve the room alias (%@)", roomIdOrAlias);
                        }];
                    }
                    else if ([roomIdOrAlias hasPrefix:@"!"] && ((MXKAccount*)accountManager.activeAccounts.firstObject).mxSession.state != MXSessionStateRunning)
                    {
                        // The user does not know the room id but this may be because their session is not yet sync'ed
                        // So, wait for the completion of the sync and then retry
                        // FIXME: Manange all user's accounts not only the first one
                        MXKAccount* account = accountManager.activeAccounts.firstObject;

                        NSLog(@"[AppDelegate] Universal link: Need to wait for the session to be sync'ed and running");
                        universalLinkFragmentPending = fragment;

                        universalLinkWaitingObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notif) {

                            // Check that 'fragment' has not been cancelled
                            if ([universalLinkFragmentPending isEqualToString:fragment])
                            {
                                // Check whether the concerned session is the associated one
                                if (notif.object == account.mxSession && account.mxSession.state == MXSessionStateRunning)
                                {
                                    NSLog(@"[AppDelegate] Universal link: The session is running. Retry the link");
                                    [self handleUniversalLinkFragment:fragment];
                                }
                            }
                        }];
                    }
                    else
                    {
                        NSLog(@"[AppDelegate] Universal link: The room (%@) is not known by any account (email invitation: %@). Display its preview to try to join it", roomIdOrAlias, queryParams ? @"YES" : @"NO");

                        // FIXME: In case of multi-account, ask the user which one to use
                        MXKAccount* account = accountManager.activeAccounts.firstObject;

                        RoomPreviewData *roomPreviewData;
                        if (queryParams)
                        {
                            // Note: the activity indicator will not disappear if the session is not ready
                            [_homeViewController stopActivityIndicator];

                            roomPreviewData = [[RoomPreviewData alloc] initWithRoomId:roomIdOrAlias emailInvitationParams:queryParams andSession:account.mxSession];
                            [self showRoomPreview:roomPreviewData];
                        }
                        else
                        {
                            roomPreviewData = [[RoomPreviewData alloc] initWithRoomId:roomIdOrAlias andSession:account.mxSession];

                            // Is it a link to an event of a room?
                            // If yes, the event will be displayed once the room is joined
                            roomPreviewData.eventId = (pathParams.count >= 3) ? pathParams[2] : nil;

                            // Try to get more information about the room before opening its preview
                            [roomPreviewData peekInRoom:^(BOOL succeeded) {

                                // Note: the activity indicator will not disappear if the session is not ready
                                [_homeViewController stopActivityIndicator];

                                [self showRoomPreview:roomPreviewData];
                            }];
                        }
                    }
                }];

                // Let's say we are handling the case
                continueUserActivity = YES;
            }
        }
        else
        {
            // There is no account. The app will display the AuthenticationVC.
            // Wait for a successful login
            NSLog(@"[AppDelegate] Universal link: The user is not logged in. Wait for a successful login");
            universalLinkFragmentPending = fragment;

            // Register an observer in order to handle new account
            universalLinkWaitingObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidAddAccountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

                // Check that 'fragment' has not been cancelled
                if ([universalLinkFragmentPending isEqualToString:fragment])
                {
                    NSLog(@"[AppDelegate] Universal link:  The user is now logged in. Retry the link");
                    [self handleUniversalLinkFragment:fragment];
                }
            }];
        }
    }
    else if ([pathParams[0] isEqualToString:@"register"])
    {
        NSLog(@"[AppDelegate] Universal link with registration parameters");
        continueUserActivity = YES;
        
        [_homeViewController showAuthenticationScreenWithRegistrationParameters:queryParams];
    }
    else
    {
        // Unknown command: Do nothing except coming back to the main screen
        NSLog(@"[AppDelegate] Universal link: TODO: Do not know what to do with the link arguments: %@", pathParams);

        [self popToHomeViewControllerAnimated:NO completion:nil];
    }

    return continueUserActivity;
}

- (void)resetPendingUniversalLink
{
    universalLinkFragmentPending = nil;
    if (universalLinkWaitingObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:universalLinkWaitingObserver];
        universalLinkWaitingObserver = nil;
    }
}

/**
 Extract params from the URL fragment part (after '#') of a vector.im Universal link:

 The fragment can contain a '?'. So there are two kinds of parameters: path params and query params.
 It is in the form of /[pathParam1]/[pathParam2]?[queryParam1Key]=[queryParam1Value]&[queryParam2Key]=[queryParam2Value]

 @param fragment the fragment to parse.
 @param outPathParams the decoded path params.
 @param outQueryParams the decoded query params. If there is no query params, it will be nil.
 */
- (void)parseUniversalLinkFragment:(NSString*)fragment outPathParams:(NSArray<NSString*> **)outPathParams outQueryParams:(NSMutableDictionary **)outQueryParams
{
    NSParameterAssert(outPathParams && outQueryParams);

    NSArray<NSString*> *pathParams;
    NSMutableDictionary *queryParams;

    NSArray<NSString*> *fragments = [fragment componentsSeparatedByString:@"?"];

    // Extract path params
    pathParams = [fragments[0] componentsSeparatedByString:@"/"];

    // Remove the first empty path param string
    pathParams = [pathParams filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];

    // URL decode each path param
    NSMutableArray<NSString*> *pathParams2 = [NSMutableArray arrayWithArray:pathParams];
    for (NSInteger i = 0; i < pathParams.count; i++)
    {
        pathParams2[i] = [pathParams2[i] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    pathParams = pathParams2;

    // Extract query params if any
    // Query params are in the form [queryParam1Key]=[queryParam1Value], so the
    // presence of at least one '=' character is mandatory
    if (fragments.count == 2 && (NSNotFound != [fragments[1] rangeOfString:@"="].location))
    {
        queryParams = [[NSMutableDictionary alloc] init];
        for (NSString *keyValue in [fragments[1] componentsSeparatedByString:@"&"])
        {
            // Get the parameter name
            NSString *key = [[keyValue componentsSeparatedByString:@"="] objectAtIndex:0];

            // Get the parameter value
            NSString *value = [[keyValue componentsSeparatedByString:@"="] objectAtIndex:1];
            if (value.length)
            {
                value = [value stringByReplacingOccurrencesOfString:@"+" withString:@" "];
                value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

                queryParams[key] = value;
            }
        }
    }

    *outPathParams = pathParams;
    *outQueryParams = queryParams;
}

#pragma mark - Matrix sessions handling

- (void)initMatrixSessions
{
    // Disable identicon use
    [MXSDKOptions sharedInstance].disableIdenticonUseForUserAvatar = YES;
    
    // Disable long press on event in bubble cells
    [MXKRoomBubbleTableViewCell disableLongPressGestureOnEvent:YES];
    
    // Set first RoomDataSource class used in Vector
    [MXKRoomDataSourceManager registerRoomDataSourceClass:RoomDataSource.class];
    
    // Register matrix session state observer in order to handle multi-sessions.
    matrixSessionStateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif)
    {
        MXSession *mxSession = (MXSession*)notif.object;
        
        // Remove by default potential call observer on matrix session state change
        if (matrixCallObserver)
        {
            [[NSNotificationCenter defaultCenter] removeObserver:matrixCallObserver];
            matrixCallObserver = nil;
        }
        
        // Check whether the concerned session is a new one
        if (mxSession.state == MXSessionStateInitialised)
        {
            // Store this new session
            [self addMatrixSession:mxSession];
            
            // Set the VoIP call stack (if supported).
            id<MXCallStack> callStack;
            
#ifdef MX_CALL_STACK_OPENWEBRTC
            callStack = [[MXOpenWebRTCCallStack alloc] init];
#endif
#ifdef MX_CALL_STACK_ENDPOINT
            callStack = [[MXEndpointCallStack alloc] initWithMatrixId:mxSession.myUser.userId];
#endif
#ifdef MX_CALL_STACK_JINGLE
            callStack = [[MXJingleCallStack alloc] init];
#endif
            if (callStack)
            {
                [mxSession enableVoIPWithCallStack:callStack];
            }
            else
            {
                // When there is no call stack, display alerts on call invites
                [self enableNoVoIPOnMatrixSession:mxSession];
            }
            
            // Each room member will be considered as a potential contact.
            [MXKContactManager sharedManager].contactManagerMXRoomSource = MXKContactManagerMXRoomSourceAll;
        }
        else if (mxSession.state == MXSessionStateStoreDataReady)
        {
            // Check whether the app user wants inApp notifications on new events for this session
            NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
            for (MXKAccount *account in mxAccounts)
            {
                if (account.mxSession == mxSession)
                {
                    [self enableInAppNotificationsForAccount:account];
                    break;
                }
            }
        }
        else if (mxSession.state == MXSessionStateClosed)
        {
            [self removeMatrixSession:mxSession];
        }
        
        // Restore call observer only if all session are running
        NSArray *mxSessions = self.mxSessions;
        BOOL shouldAddMatrixCallObserver = (mxSessions.count);
        for (mxSession in mxSessions)
        {
            if (mxSession.state != MXSessionStateRunning)
            {
                shouldAddMatrixCallObserver = NO;
                break;
            }
        }
        
        if (shouldAddMatrixCallObserver)
        {
            // A new call observer may be added here
            [self addMatrixCallObserver];
        }
    }];
    
    // Register an observer in order to handle new account
    addedAccountObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidAddAccountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        // Finalize the initialization of this new account
        MXKAccount *account = notif.object;
        if (account)
        {
            // Set the push gateway URL.
            account.pushGatewayURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"pushGatewayURL"];
            
            if (isAPNSRegistered)
            {
                // Enable push notifications by default on new added account
                account.enablePushNotifications = YES;
            }
            else
            {
                // Set up push notifications
                [self registerUserNotificationSettings];
            }
            
            // Observe inApp notifications toggle change
            [account addObserver:self forKeyPath:@"enableInAppNotifications" options:0 context:nil];
        }
    }];
    
    // Add observer to handle removed accounts
    removedAccountObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidRemoveAccountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        // Remove inApp notifications toggle change
        MXKAccount *account = notif.object;
        [account removeObserver:self forKeyPath:@"enableInAppNotifications"];
        
        // Logout the app when there is no available account
        if (![MXKAccountManager sharedManager].accounts.count)
        {
            [self logout];
        }
    }];

    [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionIgnoredUsersDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notif) {

        NSLog(@"[AppDelegate] kMXSessionIgnoredUsersDidChangeNotification received. Reload the app");

        // Reload entirely the app when a user has been ignored or unignored
        [[AppDelegate theDelegate] reloadMatrixSessions:YES];

    }];
    
    // Observe settings changes
    [[MXKAppSettings standardAppSettings]  addObserver:self forKeyPath:@"showAllEventsInRoomHistory" options:0 context:nil];
    
    // Prepare account manager
    MXKAccountManager *accountManager = [MXKAccountManager sharedManager];
    
    // Use MXFileStore as MXStore to permanently store events.
    accountManager.storeClass = [MXFileStore class];

    // Observers have been defined, we can start a matrix session for each enabled accounts.
    // except if the app is still in background.
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground)
    {
        [accountManager prepareSessionForActiveAccounts];
    }
    else
    {
        // The app is launched in background as a result of a remote notification.
        // Presently we are not able to initialize the matrix session(s) in background. (FIXME: initialize matrix session(s) in case of a background launch).
        // Patch: the account session(s) will be opened when the app will enter foreground.
        NSLog(@"[AppDelegate] initMatrixSessions: The application has been launched in background");
    }
    
    // Check whether we're already logged in
    NSArray *mxAccounts = accountManager.accounts;
    if (mxAccounts.count)
    {
        // The push gateway url is now configurable.
        // Set this url in the existing accounts when it is undefined.
        for (MXKAccount *account in mxAccounts)
        {
            if (!account.pushGatewayURL)
            {
                // Set the push gateway URL.
                account.pushGatewayURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"pushGatewayURL"];
            }
        }
        
        // Set up push notifications
        [self registerUserNotificationSettings];
        
        // Observe inApp notifications toggle change for each account
        for (MXKAccount *account in mxAccounts)
        {
            [account addObserver:self forKeyPath:@"enableInAppNotifications" options:0 context:nil];
        }
    }
}

- (NSArray*)mxSessions
{
    return [NSArray arrayWithArray:mxSessionArray];
}

- (void)addMatrixSession:(MXSession *)mxSession
{
    if (mxSession)
    {
        // Report this session to contact manager
        [[MXKContactManager sharedManager] addMatrixSession:mxSession];
        
        // Update home data sources
        [_homeViewController addMatrixSession:mxSession];
        
        [mxSessionArray addObject:mxSession];
    }
}

- (void)removeMatrixSession:(MXSession*)mxSession
{
    [[MXKContactManager sharedManager] removeMatrixSession:mxSession];
    
    // Update home data sources
    [_homeViewController removeMatrixSession:mxSession];

    // If any, disable the no VoIP support workaround
    [self disableNoVoIPOnMatrixSession:mxSession];
    
    [mxSessionArray removeObject:mxSession];
}

- (void)reloadMatrixSessions:(BOOL)clearCache
{
    // Reload all running matrix sessions
    NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    for (MXKAccount *account in mxAccounts)
    {
        [account reload:clearCache];
    }
    
    // Force back to Recents list if room details is displayed (Room details are not available until the end of initial sync)
    [self popToHomeViewControllerAnimated:NO completion:nil];
    
    if (clearCache)
    {
        // clear the media cache
        [MXKMediaManager clearCache];
    }
}

- (void)logout
{
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    isAPNSRegistered = NO;
    
    // Clear cache
    [MXKMediaManager clearCache];

#ifdef MX_CALL_STACK_ENDPOINT
    // Erase all created certificates and private keys by MXEndpointCallStack
    for (MXKAccount *account in MXKAccountManager.sharedManager.accounts)
    {
        if ([account.mxSession.callManager.callStack isKindOfClass:MXEndpointCallStack.class])
        {
            [(MXEndpointCallStack*)account.mxSession.callManager.callStack deleteData:account.mxSession.myUser.userId];
        }
    }
#endif
    
    // Logout all matrix account
    [[MXKAccountManager sharedManager] logout];
    
    // Return to authentication screen
    [_homeViewController showAuthenticationScreen];
    
    // Reset App settings
    [[MXKAppSettings standardAppSettings] reset];
    
    // Reset the contact manager
    [[MXKContactManager sharedManager] reset];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([@"showAllEventsInRoomHistory" isEqualToString:keyPath])
    {
        // Flush and restore Matrix data
        [self reloadMatrixSessions:NO];
    }
    else if ([@"enableInAppNotifications" isEqualToString:keyPath] && [object isKindOfClass:[MXKAccount class]])
    {
        [self enableInAppNotificationsForAccount:(MXKAccount*)object];
    }
}

- (void)addMatrixCallObserver
{
    if (matrixCallObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:matrixCallObserver];
    }
    
    // Register call observer in order to handle new opened session
    matrixCallObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallManagerNewCall object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif)
    {
        
        // Ignore the call if a call is already in progress
        if (!currentCallViewController)
        {
            MXCall *mxCall = (MXCall*)notif.object;
            
            currentCallViewController = [MXKCallViewController callViewController:mxCall];
            currentCallViewController.delegate = self;
            
            // FIXME GFO Check whether present call from self.window.rootViewController is working
            [self.window.rootViewController presentViewController:currentCallViewController animated:YES completion:^{
                currentCallViewController.isPresented = YES;
            }];
            
            // Hide system status bar
            [UIApplication sharedApplication].statusBarHidden = YES;
        }
    }];
}

#pragma mark - Matrix Accounts handling

- (void)enableInAppNotificationsForAccount:(MXKAccount*)account
{
    if (account.mxSession)
    {
        if (account.enableInAppNotifications)
        {
            // Build MXEvent -> NSString formatter
            EventFormatter *eventFormatter = [[EventFormatter alloc] initWithMatrixSession:account.mxSession];
            eventFormatter.isForSubtitle = YES;
            
            [account listenToNotifications:^(MXEvent *event, MXRoomState *roomState, MXPushRule *rule) {
                
                // Check conditions to display this notification
                if (![self.visibleRoomId isEqualToString:event.roomId]
                    && !self.window.rootViewController.presentedViewController)
                {
                    MXKEventFormatterError error;
                    NSString* messageText = [eventFormatter stringFromEvent:event withRoomState:roomState error:&error];
                    if (messageText.length && (error == MXKEventFormatterErrorNone))
                    {
                        
                        // Removing existing notification (if any)
                        if (self.mxInAppNotification)
                        {
                            [self.mxInAppNotification dismiss:NO];
                        }
                        
                        // Check whether tweak is required
                        for (MXPushRuleAction *ruleAction in rule.actions)
                        {
                            if (ruleAction.actionType == MXPushRuleActionTypeSetTweak)
                            {
                                if ([[ruleAction.parameters valueForKey:@"set_tweak"] isEqualToString:@"sound"])
                                {
                                    // Play system sound (VoicemailReceived)
                                    AudioServicesPlaySystemSound (1002);
                                }
                            }
                        }
                        
                        __weak typeof(self) weakSelf = self;
                        self.mxInAppNotification = [[MXKAlert alloc] initWithTitle:roomState.displayname
                                                                           message:messageText
                                                                             style:MXKAlertStyleAlert];
                        self.mxInAppNotification.cancelButtonIndex = [self.mxInAppNotification addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                                                                            style:MXKAlertActionStyleDefault
                                                                                                          handler:^(MXKAlert *alert)
                                                                      {
                                                                          weakSelf.mxInAppNotification = nil;
                                                                          [account updateNotificationListenerForRoomId:event.roomId ignore:YES];
                                                                      }];
                        [self.mxInAppNotification addActionWithTitle:NSLocalizedStringFromTable(@"view", @"Vector", nil)
                                                               style:MXKAlertActionStyleDefault
                                                             handler:^(MXKAlert *alert)
                         {
                             weakSelf.mxInAppNotification = nil;
                             // Show the room
                             [weakSelf showRoom:event.roomId andEventId:nil withMatrixSession:account.mxSession];
                         }];
                        
                        [self.mxInAppNotification showInViewController:self.window.rootViewController];
                    }
                }
            }];
        }
        else
        {
            [account removeNotificationListener];
        }
    }
    
    if (self.mxInAppNotification)
    {
        [self.mxInAppNotification dismiss:NO];
        self.mxInAppNotification = nil;
    }
}

- (void)selectMatrixAccount:(void (^)(MXKAccount *selectedAccount))onSelection
{
    NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    
    if (mxAccounts.count == 1)
    {
        if (onSelection)
        {
            onSelection(mxAccounts.firstObject);
        }
    }
    else if (mxAccounts.count > 1)
    {
        if (accountPicker)
        {
            [accountPicker dismiss:NO];
        }
        
        accountPicker = [[MXKAlert alloc] initWithTitle:[NSBundle mxk_localizedStringForKey:@"select_account"] message:nil style:MXKAlertStyleActionSheet];
        
        __weak typeof(self) weakSelf = self;
        for(MXKAccount *account in mxAccounts)
        {
            [accountPicker addActionWithTitle:account.mxCredentials.userId style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                strongSelf->accountPicker = nil;
                
                if (onSelection)
                {
                    onSelection(account);
                }
            }];
        }
        
        accountPicker.cancelButtonIndex = [accountPicker addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
            
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->accountPicker = nil;
            
            if (onSelection)
            {
                onSelection(nil);
            }
        }];
        
        accountPicker.sourceView = self.window.rootViewController.view;
        [accountPicker showInViewController:self.window.rootViewController];
    }
}

#pragma mark - Matrix Rooms handling

- (void)showRoom:(NSString*)roomId andEventId:(NSString*)eventId withMatrixSession:(MXSession*)mxSession
{
    [self restoreInitialDisplay:^{
        
        // Select room to display its details (dispatch this action in order to let TabBarController end its refresh)
        [_homeViewController selectRoomWithId:roomId andEventId:eventId inMatrixSession:mxSession];
        
    }];
}

- (void)showRoomPreview:(RoomPreviewData*)roomPreviewData
{
    [self restoreInitialDisplay:^{
        [_homeViewController showRoomPreview:roomPreviewData];
    }];
}

- (void)setVisibleRoomId:(NSString *)roomId
{
    if (roomId)
    {
        // Enable inApp notification for this room in all existing accounts.
        NSArray *mxAccounts = [MXKAccountManager sharedManager].accounts;
        for (MXKAccount *account in mxAccounts)
        {
            [account updateNotificationListenerForRoomId:roomId ignore:NO];
        }
    }
    
    _visibleRoomId = roomId;
}

- (void)startPrivateOneToOneRoomWithUserId:(NSString*)userId completion:(void (^)(void))completion
{
    // Handle here potential multiple accounts
    [self selectMatrixAccount:^(MXKAccount *selectedAccount) {
        
        MXSession *mxSession = selectedAccount.mxSession;
        
        if (mxSession)
        {
            MXRoom* mxRoom = [mxSession privateOneToOneRoomWithUserId:userId];
            
            // if the room exists
            if (mxRoom)
            {
                // open it
                [self showRoom:mxRoom.state.roomId andEventId:nil withMatrixSession:mxSession];
                
                if (completion)
                {
                    completion();
                }
            }
            else
            {
                // create a new room
                [mxSession createRoom:nil
                           visibility:kMXRoomDirectoryVisibilityPrivate
                            roomAlias:nil
                                topic:nil
                              success:^(MXRoom *room) {
                                  
                                  // Invite the other user only if it is defined and not onself
                                  if (userId && ![mxSession.myUser.userId isEqualToString:userId])
                                  {
                                      // Add the user
                                      [room inviteUser:userId
                                               success:^{
                                               }
                                               failure:^(NSError *error) {
                                                   
                                                   NSLog(@"[AppDelegate] %@ invitation failed (roomId: %@)", userId, room.state.roomId);
                                                   //Alert user
                                                   [self showErrorAsAlert:error];
                                                   
                                               }];
                                  }
                                  
                                  // Open created room
                                  [self showRoom:room.state.roomId andEventId:nil withMatrixSession:mxSession];
                                  
                                  if (completion)
                                  {
                                      completion();
                                  }
                                  
                              }
                              failure:^(NSError *error) {
                                  
                                  NSLog(@"[AppDelegate] Create room failed");
                                  //Alert user
                                  [self showErrorAsAlert:error];
                                  
                                  if (completion)
                                  {
                                      completion();
                                  }
                                  
                              }];
            }
        }
        else if (completion)
        {
            completion();
        }
        
    }];
}

#pragma mark - MXKCallViewControllerDelegate

- (void)dismissCallViewController:(MXKCallViewController *)callViewController
{
    if (callViewController == currentCallViewController)
    {
        
        if (callViewController.isPresented)
        {
            BOOL callIsEnded = (callViewController.mxCall.state == MXCallStateEnded);
            NSLog(@"Call view controller is dismissed (%d)", callIsEnded);
            
            [callViewController dismissViewControllerAnimated:YES completion:^{
                callViewController.isPresented = NO;
                
                if (!callIsEnded)
                {
                    [self addCallStatusBar];
                }
            }];
            
            if (callIsEnded)
            {
                [self removeCallStatusBar];
                
                // Restore system status bar
                [UIApplication sharedApplication].statusBarHidden = NO;
                
                // Release properly
                currentCallViewController.mxCall.delegate = nil;
                currentCallViewController.delegate = nil;
                currentCallViewController = nil;
            }
        } else
        {
            // Here the presentation of the call view controller is in progress
            // Postpone the dismiss
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self dismissCallViewController:callViewController];
            });
        }
    }
}

#pragma mark - Call status handling

- (void)addCallStatusBar
{
    // Add a call status bar
    CGSize topBarSize = CGSizeMake([[UIScreen mainScreen] applicationFrame].size.width, 44);
    
    callStatusBarWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0,0, topBarSize.width,topBarSize.height)];
    callStatusBarWindow.windowLevel = UIWindowLevelStatusBar;
    
    // Create statusBarButton
    callStatusBarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    callStatusBarButton.frame = CGRectMake(0, 0, topBarSize.width,topBarSize.height);
    NSString *btnTitle = NSLocalizedStringFromTable(@"return_to_call", @"Vector", nil);
    
    [callStatusBarButton setTitle:btnTitle forState:UIControlStateNormal];
    [callStatusBarButton setTitle:btnTitle forState:UIControlStateHighlighted];
    callStatusBarButton.titleLabel.textColor = [UIColor whiteColor];
    
    [callStatusBarButton setBackgroundColor:[UIColor blueColor]];
    [callStatusBarButton addTarget:self action:@selector(returnToCallView) forControlEvents:UIControlEventTouchUpInside];
    
    // Place button into the new window
    [callStatusBarWindow addSubview:callStatusBarButton];
    
    callStatusBarWindow.hidden = NO;
    [self statusBarDidChangeFrame];
    
    // We need to listen to the system status bar size change events to refresh the root controller frame.
    // Else the navigation bar position will be wrong.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusBarDidChangeFrame)
                                                 name:UIApplicationDidChangeStatusBarFrameNotification
                                               object:nil];
}

- (void)removeCallStatusBar
{
    if (callStatusBarWindow)
    {
        
        // Hide & destroy it
        callStatusBarWindow.hidden = YES;
        [self statusBarDidChangeFrame];
        [callStatusBarButton removeFromSuperview];
        callStatusBarButton = nil;
        callStatusBarWindow = nil;
        
        // No more need to listen to system status bar changes
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    }
}

- (void)returnToCallView
{
    [self removeCallStatusBar];
    
    // FIXME GFO check whether self.window.rootViewController may present the call
    [self.window.rootViewController presentViewController:currentCallViewController animated:YES completion:^{
        currentCallViewController.isPresented = YES;
    }];
}

- (void)statusBarDidChangeFrame
{
    UIApplication *app = [UIApplication sharedApplication];
    UIViewController *rootController = app.keyWindow.rootViewController;
    
    // Refresh the root view controller frame
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    if (callStatusBarWindow)
    {
        // Substract the height of call status bar from the frame.
        CGFloat callBarStatusHeight = callStatusBarWindow.frame.size.height;
        
        CGFloat delta = callBarStatusHeight - frame.origin.y;
        frame.origin.y = callBarStatusHeight;
        frame.size.height -= delta;
    }
    rootController.view.frame = frame;
    [rootController.view setNeedsLayout];
}

#pragma mark - SplitViewController delegate

- (nullable UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController
{
    UIViewController *topViewController = _homeNavigationController.topViewController;
    
    // Check the case where we don't want to use as a secondary view controller the top view controller
    // of the navigation controller of the home view controller.
    if ([topViewController isKindOfClass:[DirectoryViewController class]]
        || [topViewController isKindOfClass:[SettingsViewController class]]
        || [topViewController isKindOfClass:[ContactDetailsViewController class]])
    {
        if (_secondaryNavigationController)
        {
            // Return the default secondary view controller to keep on primaryViewController side
            // the Directory, the Settings or the Contact details view controller.
            return _secondaryNavigationController;
        }
        else
        {
            // Return a fake room view controller for the secondary view controller.
            return [RoomViewController roomViewController];
        }
    }
    return nil;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController
{
    RoomViewController *roomViewController;
    
    if ([secondaryViewController isKindOfClass:[RoomViewController class]])
    {
        roomViewController = (RoomViewController*)secondaryViewController;
    }
    else if ([secondaryViewController isKindOfClass:[UINavigationController class]] &&
             [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[RoomViewController class]])
    {
        roomViewController = (RoomViewController*)[(UINavigationController *)secondaryViewController topViewController];
    }
    
    if (roomViewController && roomViewController.roomDataSource == nil && roomViewController.roomPreviewData == nil)
    {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
    // oniPad devices, force to display the primary and the secondary viewcontroller
    // to avoid empty room View Controller in portrait orientation
    // else, the user cannot select a room
    return NO;
}

#pragma mark - Status Bar Tap handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.window];
    
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    
    if (CGRectContainsPoint(statusBarFrame, point))
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAppDelegateDidTapStatusBarNotification object:nil];
    }
}

#pragma mark - No call support
/**
 Display a "Call not supported" alert when the session receives a call invitation.

 @param mxSession the session to spy
 */
- (void)enableNoVoIPOnMatrixSession:(MXSession*)mxSession
{
    // Listen to call events
    callEventsListeners[@(mxSession.hash)] =
    [mxSession listenToEventsOfTypes:@[
                                       kMXEventTypeStringCallInvite,
                                       kMXEventTypeStringCallCandidates,
                                       kMXEventTypeStringCallAnswer,
                                       kMXEventTypeStringCallHangup
                                       ]
                             onEvent:^(MXEvent *event, MXTimelineDirection direction, id customObject)
    {
        if (MXTimelineDirectionForwards == direction)
        {
            switch (event.eventType)
            {
                case MXEventTypeCallInvite:
                {
                    if (noCallSupportAlert)
                    {
                        [noCallSupportAlert dismiss:NO];
                    }

                    MXCallInviteEventContent *callInviteEventContent = [MXCallInviteEventContent modelFromJSON:event.content];

                    // Sanity and invite expiration checks
                    if (!callInviteEventContent || event.age >= callInviteEventContent.lifetime)
                    {
                        return;
                    }

                    MXUser *caller = [mxSession userWithUserId:event.sender];
                    NSString *callerDisplayname = caller.displayname;
                    if (!callerDisplayname.length)
                    {
                        callerDisplayname = event.sender;
                    }

                    NSString *message = [NSString stringWithFormat:NSLocalizedStringFromTable(@"no_voip", @"Vector", nil), callerDisplayname];

                    noCallSupportAlert = [[MXKAlert alloc] initWithTitle:NSLocalizedStringFromTable(@"no_voip_title", @"Vector", nil)
                                                                 message:message
                                                                   style:MXKAlertStyleAlert];

                    __weak typeof(self) weakSelf = self;

                    noCallSupportAlert.cancelButtonIndex = [noCallSupportAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ignore"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        strongSelf->noCallSupportAlert = nil;

                    }];

                    [noCallSupportAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"reject_call"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                        // Reject the call by sending the hangup event
                        NSDictionary *content = @{
                                                  @"call_id": callInviteEventContent.callId,
                                                  @"version": @(0)
                                                  };

                        [mxSession.matrixRestClient sendEventToRoom:event.roomId eventType:kMXEventTypeStringCallHangup content:content success:nil failure:^(NSError *error) {
                            NSLog(@"[AppDelegate] enableNoVoIPOnMatrixSession: ERROR: Cannot send m.call.hangup event. Error: %@", error);
                        }];

                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        strongSelf->noCallSupportAlert = nil;

                    }];

                    [noCallSupportAlert showInViewController:self.window.rootViewController];
                    break;
                }

                case MXEventTypeCallAnswer:
                case MXEventTypeCallHangup:
                    // The call has ended. The alert is no more needed.
                    if (noCallSupportAlert)
                    {
                        [noCallSupportAlert dismiss:YES];
                        noCallSupportAlert = nil;
                    }
                    break;

                default:
                    break;
            }
        }
    }];

}

- (void)disableNoVoIPOnMatrixSession:(MXSession*)mxSession
{
    // Stop listening to the call events of this session 
    [mxSession removeListener:callEventsListeners[@(mxSession.hash)]];
    [callEventsListeners removeObjectForKey:@(mxSession.hash)];
}

@end
