/*
 Copyright 2014 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
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

#import "RoomViewController.h"

#import "DirectoryViewController.h"
#import "SettingsViewController.h"
#import "ContactDetailsViewController.h"

#import "BugReportViewController.h"

#import "NSBundle+MatrixKit.h"
#import "MatrixSDK/MatrixSDK.h"

#import "Tools.h"
#import "MXRoom+Riot.h"
#import "WidgetManager.h"

#import "AFNetworkReachabilityManager.h"

#import <AudioToolbox/AudioToolbox.h>

#import "CallViewController.h"

//#define MX_CALL_STACK_OPENWEBRTC
#ifdef MX_CALL_STACK_OPENWEBRTC
#import <MatrixOpenWebRTCWrapper/MatrixOpenWebRTCWrapper.h>
#endif

#ifdef MX_CALL_STACK_ENDPOINT
#import <MatrixEndpointWrapper/MatrixEndpointWrapper.h>
#endif

#include <MatrixSDK/MXJingleCallStack.h>

#include <MatrixSDK/MXUIKitBackgroundModeHandler.h>

#define CALL_STATUS_BAR_HEIGHT 44

#define MAKE_STRING(x) #x
#define MAKE_NS_STRING(x) @MAKE_STRING(x)

NSString *const kAppDelegateDidTapStatusBarNotification = @"kAppDelegateDidTapStatusBarNotification";
NSString *const kAppDelegateNetworkStatusDidChangeNotification = @"kAppDelegateNetworkStatusDidChangeNotification";

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
    CallViewController *currentCallViewController;
    
    /**
     Account picker used in case of multiple account.
     */
    UIAlertController *accountPicker;
    
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
     The potential room alias related to the fragment of the universal link being processing.
     Only one alias is handled at a time, the key is the room id and the value is the alias.
     */
    NSDictionary *universalLinkFragmentPendingRoomAlias;
    
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
    UIAlertController *noCallSupportAlert;
    
    /**
     Prompt to ask the user to log in again.
     */
    UIAlertController *cryptoDataCorruptedAlert;
    
    /**
     The launch animation container view
     */
    UIView *launchAnimationContainerView;
    NSDate *launchAnimationStart;
}

@property (strong, nonatomic) UIAlertController *mxInAppNotification;

@property (nonatomic, nullable, copy) void (^registrationForRemoteNotificationsCompletion)(NSError *);

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
    
    if (_isOffline != isOffline)
    {
        _isOffline = isOffline;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kAppDelegateNetworkStatusDidChangeNotification object:nil];
    }
}

- (UINavigationController*)secondaryNavigationController
{
    UIViewController* rootViewController = self.window.rootViewController;
    
    if ([rootViewController isKindOfClass:[UISplitViewController class]])
    {
        UISplitViewController *splitViewController = (UISplitViewController *)rootViewController;
        if (splitViewController.viewControllers.count == 2)
        {
            UIViewController *secondViewController = [splitViewController.viewControllers lastObject];
            
            if ([secondViewController isKindOfClass:[UINavigationController class]])
            {
                return (UINavigationController*)secondViewController;
            }
        }
    }
    
    return nil;
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
    
    // Log app information
    NSString *appDisplayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSString* appVersion = [AppDelegate theDelegate].appVersion;
    NSString* build = [AppDelegate theDelegate].build;
    
    NSLog(@"------------------------------");
    NSLog(@"Application info:");
    NSLog(@"%@ version: %@", appDisplayName, appVersion);
    NSLog(@"MatrixKit version: %@", MatrixKitVersion);
    NSLog(@"MatrixSDK version: %@", MatrixSDKVersion);
    NSLog(@"Build: %@\n", build);
    NSLog(@"------------------------------\n");

    // Set up runtime language and fallback
    NSString *langage = [[NSUserDefaults standardUserDefaults] objectForKey:@"appLanguage"];;
    [NSBundle mxk_setLanguage:langage];
    [NSBundle mxk_setFallbackLanguage:@"en"];

    // Define the navigation bar text color
    [[UINavigationBar appearance] setTintColor:kRiotColorGreen];
    
    // Customize the localized string table
    [NSBundle mxk_customizeLocalizedStringTableName:@"Vector"];
    
    mxSessionArray = [NSMutableArray array];
    callEventsListeners = [NSMutableDictionary dictionary];
    
    // To simplify navigation into the app, we retrieve here the main navigation controller and the tab bar controller.
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    splitViewController.delegate = self;
    
    _masterNavigationController = [splitViewController.viewControllers objectAtIndex:0];
    _masterTabBarController = _masterNavigationController.viewControllers.firstObject;
    
    // Force the background color of the fake view controller displayed when there is no details.
    UINavigationController *secondNavController = self.secondaryNavigationController;
    if (secondNavController)
    {
        secondNavController.navigationBar.barTintColor = kRiotPrimaryBgColor;
        secondNavController.topViewController.view.backgroundColor = kRiotPrimaryBgColor;
    }
    
    // on IOS 8 iPad devices, force to display the primary and the secondary viewcontroller
    // to avoid empty room View Controller in portrait orientation
    // else, the user cannot select a room
    // shouldHideViewController delegate method is also implemented
    if ([(NSString*)[UIDevice currentDevice].model hasPrefix:@"iPad"])
    {
        splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    }
    
    // Sanity check
    NSAssert(_masterTabBarController, @"Something wrong in Main.storyboard");
    
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
        [self.errorNotification dismissViewControllerAnimated:NO completion:nil];
        self.errorNotification = nil;
    }
    
    if (accountPicker)
    {
        [accountPicker dismissViewControllerAnimated:NO completion:nil];
        accountPicker = nil;
    }
    
    if (noCallSupportAlert)
    {
        [noCallSupportAlert dismissViewControllerAnimated:NO completion:nil];
        noCallSupportAlert = nil;
    }
    
    if (cryptoDataCorruptedAlert)
    {
        [cryptoDataCorruptedAlert dismissViewControllerAnimated:NO completion:nil];
        cryptoDataCorruptedAlert = nil;
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
    
    // check if some media must be released to reduce the cache size
    [MXMediaManager reduceCacheSizeToInsert:0];
    
    // Hide potential notification
    if (self.mxInAppNotification)
    {
        [self.mxInAppNotification dismissViewControllerAnimated:NO completion:nil];
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
    
    // Observe crypto data storage corruption
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSessionCryptoDidCorruptData:) name:kMXSessionCryptoDidCorruptDataNotification object:nil];
    
    // Resume all existing matrix sessions
    NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    for (MXKAccount *account in mxAccounts)
    {
        [account resume];
    }
    
    // Refresh local contact from the contact book.
    [self refreshLocalContacts];
    
    _isAppForeground = YES;
    
    [self handleLaunchAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"[AppDelegate] applicationWillTerminate");
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    [self stopGoogleAnalytics];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler
{
    BOOL continueUserActivity = NO;
    
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
                
                // Enable error notifications
                isErrorNotificationSuspended = NO;
                
                if (noCallSupportAlert)
                {
                    NSLog(@"[AppDelegate] restoreInitialDisplay: keep visible noCall support alert");
                    [self showNotificationAlert:noCallSupportAlert];
                }
                else if (cryptoDataCorruptedAlert)
                {
                    NSLog(@"[AppDelegate] restoreInitialDisplay: keep visible log in again");
                    [self showNotificationAlert:cryptoDataCorruptedAlert];
                }
                // Check whether an error notification is pending
                else if (_errorNotification)
                {
                    [self showNotificationAlert:_errorNotification];
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
            if (_errorNotification)
            {
                [self showNotificationAlert:_errorNotification];
            }
        }];
    }
}

- (UIAlertController*)showErrorAsAlert:(NSError*)error
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
    
    [_errorNotification dismissViewControllerAnimated:NO completion:nil];
    
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
    
    _errorNotification = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    [_errorNotification addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             
                                                             [AppDelegate theDelegate].errorNotification = nil;
                                                             
                                                         }]];
    // Display the error notification
    if (!isErrorNotificationSuspended)
    {
        [_errorNotification mxk_setAccessibilityIdentifier:@"AppDelegateErrorAlert"];
        [self showNotificationAlert:_errorNotification];
    }
    
    // Switch in offline mode in case of network reachability error
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorNotConnectedToInternet)
    {
        self.isOffline = YES;
    }
    
    return self.errorNotification;
}

- (void)showNotificationAlert:(UIAlertController*)alert
{
    if (self.window.rootViewController.presentedViewController)
    {
        [alert popoverPresentationController].sourceView = self.window.rootViewController.presentedViewController.view;
        [alert popoverPresentationController].sourceRect = self.window.rootViewController.presentedViewController.view.bounds;
        [self.window.rootViewController.presentedViewController presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        [alert popoverPresentationController].sourceView = self.window.rootViewController.view;
        [alert popoverPresentationController].sourceRect = self.window.rootViewController.view.bounds;
        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

- (void)onSessionCryptoDidCorruptData:(NSNotification *)notification
{
    NSString *userId = notification.object;
    
    MXKAccount *account = [[MXKAccountManager sharedManager] accountForUserId:userId];
    if (account)
    {
        if (cryptoDataCorruptedAlert)
        {
            [cryptoDataCorruptedAlert dismissViewControllerAnimated:NO completion:nil];
        }
        
        cryptoDataCorruptedAlert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:NSLocalizedStringFromTable(@"e2e_need_log_in_again", @"Vector", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        __weak typeof(self) weakSelf = self;
        
        [cryptoDataCorruptedAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"later"]
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       
                                                                       if (weakSelf)
                                                                       {
                                                                           typeof(self) self = weakSelf;
                                                                           self->cryptoDataCorruptedAlert = nil;
                                                                       }
                                                                       
                                                                   }]];
        
        [cryptoDataCorruptedAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"settings_sign_out"]
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       
                                                                       if (weakSelf)
                                                                       {
                                                                           typeof(self) self = weakSelf;
                                                                           self->cryptoDataCorruptedAlert = nil;
                                                                           
                                                                           [[MXKAccountManager sharedManager] removeAccount:account completion:nil];
                                                                       }
                                                                       
                                                                   }]];
        
        [self showNotificationAlert:cryptoDataCorruptedAlert];
    }
}

#pragma mark

- (void)popToHomeViewControllerAnimated:(BOOL)animated completion:(void (^)())completion
{
    UINavigationController *secondNavController = self.secondaryNavigationController;
    if (secondNavController)
    {
        [secondNavController popToRootViewControllerAnimated:animated];
    }
    
    // Force back to the main screen if this is not the one that is displayed
    if (_masterTabBarController && _masterTabBarController != _masterNavigationController.visibleViewController)
    {
        // Listen to the masterNavigationController changes
        // We need to be sure that masterTabBarController is back to the screen
        popToHomeViewControllerCompletion = completion;
        _masterNavigationController.delegate = self;
        
        [_masterNavigationController popToViewController:_masterTabBarController animated:animated];
    }
    else
    {
        // Select the Home tab
        _masterTabBarController.selectedIndex = TABBAR_HOME_INDEX;
        
        if (completion)
        {
            completion();
        }
    }
}

#pragma mark - UINavigationController delegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (viewController == _masterTabBarController)
    {
        _masterNavigationController.delegate = nil;
        
        // For unknown reason, the navigation bar is not restored correctly by [popToViewController:animated:]
        // when a ViewController has hidden it (see MXKAttachmentsViewController).
        // Patch: restore navigation bar by default here.
        _masterNavigationController.navigationBarHidden = NO;
        
        // Release the current selected item (room/contact/...).
        [_masterTabBarController releaseSelectedItem];
        
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
            
#ifdef DEBUG
            // Disable GAI in debug as it pollutes stats and crashes in GA
            gai.dryRun = YES;
#endif
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
        // Do not show the crash report dialog if it is already displayed
        if ([self.window.rootViewController.childViewControllers[0] isKindOfClass:[UINavigationController class]]
            && [((UINavigationController*)self.window.rootViewController.childViewControllers[0]).visibleViewController isKindOfClass:[BugReportViewController class]])
        {
            return;
        }
        
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

- (void)registerForRemoteNotificationsWithCompletion:(nullable void (^)(NSError *))completion
{
    self.registrationForRemoteNotificationsCompletion = completion;
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    // Register for remote notifications only if user provide access to notification feature
    if (notificationSettings.types != UIUserNotificationTypeNone)
    {
        [self registerForRemoteNotificationsWithCompletion:nil];
    }
    else
    {
        // Clear existing token
        MXKAccountManager* accountManager = [MXKAccountManager sharedManager];
        [accountManager setApnsDeviceToken:nil];
    }
}

- (void)application:(UIApplication*)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    NSUInteger len = ((deviceToken.length > 8) ? 8 : deviceToken.length / 2);
    NSLog(@"[AppDelegate] Got APNS token! (%@ ...)", [deviceToken subdataWithRange:NSMakeRange(0, len)]);
    
    MXKAccountManager* accountManager = [MXKAccountManager sharedManager];
    [accountManager setApnsDeviceToken:deviceToken];
    
    isAPNSRegistered = YES;
    
    if (self.registrationForRemoteNotificationsCompletion)
    {
        self.registrationForRemoteNotificationsCompletion(nil);
        self.registrationForRemoteNotificationsCompletion = nil;
    }
}

- (void)application:(UIApplication*)app didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"[AppDelegate] Failed to register for APNS: %@", error);
    
    if (self.registrationForRemoteNotificationsCompletion)
    {
        self.registrationForRemoteNotificationsCompletion(error);
        self.registrationForRemoteNotificationsCompletion = nil;
    }
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

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    // iOS 10 (at least up to GM beta release) does not call application:didReceiveRemoteNotification:fetchCompletionHandler:
    // when the user clicks on a notification but it calls this deprecated version
    // of didReceiveRemoteNotification.
    // Use this method as a workaround as adviced at http://stackoverflow.com/a/39419245
    NSLog(@"[AppDelegate] didReceiveRemoteNotification (deprecated version)");
    
    [self application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result) {
    }];
}

- (void)refreshApplicationIconBadgeNumber
{
    // Consider the total number of missed discussions including the invites.
    NSUInteger count = [self.masterTabBarController missedDiscussionsCount];
    
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
        
        [identityRestClient submit3PIDValidationToken:queryParams[@"token"] medium:kMX3PIDMediumEmail clientSecret:queryParams[@"client_secret"] sid:queryParams[@"sid"] success:^{
            
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
            
            NSLog(@"[AppDelegate] handleUniversalLink. Error: submitToken failed");
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
    
    NSString *roomIdOrAlias;
    NSString *eventId;
    NSString *userId;
    
    // Check permalink to room or event
    if ([pathParams[0] isEqualToString:@"room"] && pathParams.count >= 2)
    {
        // The link is the form of "/room/[roomIdOrAlias]" or "/room/[roomIdOrAlias]/[eventId]"
        roomIdOrAlias = pathParams[1];
        
        // Is it a link to an event of a room?
        eventId = (pathParams.count >= 3) ? pathParams[2] : nil;
    }
    else if (([pathParams[0] hasPrefix:@"#"] || [pathParams[0] hasPrefix:@"!"]) && pathParams.count >= 1)
    {
        // The link is the form of "/#/[roomIdOrAlias]" or "/#/[roomIdOrAlias]/[eventId]"
        // Such links come from matrix.to permalinks
        roomIdOrAlias = pathParams[0];
        eventId = (pathParams.count >= 2) ? pathParams[1] : nil;
    }

    // Check permalink to a user
    else if ([pathParams[0] isEqualToString:@"user"] && pathParams.count == 2)
    {
        // The link is the form of "/user/userId"
        userId = pathParams[1];
    }
    else if ([pathParams[0] hasPrefix:@"@"] && pathParams.count == 1)
    {
        // The link is the form of "/#/[userId]"
        // Such links come from matrix.to permalinks
        userId = pathParams[0];
    }
    
    // Check the conditions to keep the room alias information of a pending fragment.
    if (universalLinkFragmentPendingRoomAlias)
    {
        if (!roomIdOrAlias || !universalLinkFragmentPendingRoomAlias[roomIdOrAlias])
        {
            universalLinkFragmentPendingRoomAlias = nil;
        }
    }
    
    if (roomIdOrAlias)
    {
        if (accountManager.activeAccounts.count)
        {
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
                    
                    if ([_masterTabBarController.selectedViewController isKindOfClass:MXKViewController.class])
                    {
                        MXKViewController *homeViewController = (MXKViewController*)_masterTabBarController.selectedViewController;
                        
                        [homeViewController startActivityIndicator];
                        
                        if ([roomIdOrAlias hasPrefix:@"#"])
                        {
                            // The alias may be not part of user's rooms states
                            // Ask the HS to resolve the room alias into a room id and then retry
                            universalLinkFragmentPending = fragment;
                            MXKAccount* account = accountManager.activeAccounts.firstObject;
                            [account.mxSession.matrixRestClient roomIDForRoomAlias:roomIdOrAlias success:^(NSString *roomId) {
                                
                                // Note: the activity indicator will not disappear if the session is not ready
                                [homeViewController stopActivityIndicator];
                                
                                // Check that 'fragment' has not been cancelled
                                if ([universalLinkFragmentPending isEqualToString:fragment])
                                {
                                    // Retry opening the link but with the returned room id
                                    NSString *newUniversalLinkFragment =
                                    [fragment stringByReplacingOccurrencesOfString:[roomIdOrAlias stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                                                        withString:[roomId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                                    
                                    universalLinkFragmentPendingRoomAlias = @{roomId: roomIdOrAlias};
                                    
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
                                [homeViewController stopActivityIndicator];
                                
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
                                    [homeViewController stopActivityIndicator];
                                    
                                    // If no data is available for this room, we name it with the known room alias (if any).
                                    if (!succeeded && universalLinkFragmentPendingRoomAlias[roomIdOrAlias])
                                    {
                                        roomPreviewData.roomName = universalLinkFragmentPendingRoomAlias[roomIdOrAlias];
                                    }
                                    universalLinkFragmentPendingRoomAlias = nil;
                                    
                                    [self showRoomPreview:roomPreviewData];
                                }];
                            }
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
    else if (userId)
    {
        // Check there is an account that knows this user
        MXUser *mxUser;
        MXKAccount *account = [accountManager accountKnowingUserWithUserId:userId];
        if (account)
        {
            mxUser = [account.mxSession userWithUserId:userId];
        }

        // Prepare the display name of this user
        NSString *displayName;
        if (mxUser)
        {
            displayName = (mxUser.displayname.length > 0) ? mxUser.displayname : userId;
        }
        else
        {
            displayName = userId;
        }

        // Create the contact related to this member
        MXKContact *contact = [[MXKContact alloc] initMatrixContactWithDisplayName:displayName andMatrixID:userId];
        [self showContact:contact];

        continueUserActivity = YES;
    }
    else if ([pathParams[0] isEqualToString:@"register"])
    {
        NSLog(@"[AppDelegate] Universal link with registration parameters");
        continueUserActivity = YES;
        
        [_masterTabBarController showAuthenticationScreenWithRegistrationParameters:queryParams];
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
    NSLog(@"[AppDelegate] initMatrixSessions");
    
    MXSDKOptions *sdkOptions = [MXSDKOptions sharedInstance];
    
    // Set the App Group identifier.
    sdkOptions.applicationGroupIdentifier = @"group.im.vector";
    
    // Define the media cache version
    sdkOptions.mediaCacheAppVersion = 0;
    
    // Enable e2e encryption for newly created MXSession
    sdkOptions.enableCryptoWhenStartingMXSession = YES;
    
    // Disable identicon use
    sdkOptions.disableIdenticonUseForUserAvatar = YES;
    
    // Enable SDK stats upload to GA
    sdkOptions.enableGoogleAnalytics = YES;
    
    // Use UIKit BackgroundTask for handling background tasks in the SDK
    sdkOptions.backgroundModeHandler = [[MXUIKitBackgroundModeHandler alloc] init];

    // Get modular widget events in rooms histories
    [[MXKAppSettings standardAppSettings] addSupportedEventTypes:@[kWidgetEventTypeString]];
    
    // Disable long press on event in bubble cells
    [MXKRoomBubbleTableViewCell disableLongPressGestureOnEvent:YES];
    
    // Set first RoomDataSource class used in Vector
    [MXKRoomDataSourceManager registerRoomDataSourceClass:RoomDataSource.class];
    
    // Register matrix session state observer in order to handle multi-sessions.
    matrixSessionStateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
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

            // Send read receipts for modular widgets events too
            NSMutableArray<MXEventTypeString> *acknowledgableEventTypes = [NSMutableArray arrayWithArray:mxSession.acknowledgableEventTypes];
            [acknowledgableEventTypes addObject:kWidgetEventTypeString];
            mxSession.acknowledgableEventTypes = acknowledgableEventTypes;
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
        
        [self handleLaunchAnimation];
    }];
    
    // Register an observer in order to handle new account
    addedAccountObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidAddAccountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        // Finalize the initialization of this new account
        MXKAccount *account = notif.object;
        if (account)
        {
            // Replace default room summary updater
            EventFormatter *eventFormatter = [[EventFormatter alloc] initWithMatrixSession:account.mxSession];
            eventFormatter.isForSubtitle = YES;
            account.mxSession.roomSummaryUpdateDelegate = eventFormatter;
            
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
        
        // Load the local contacts on first account creation.
        if ([MXKAccountManager sharedManager].accounts.count == 1)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self refreshLocalContacts];
                
            });
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
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionDidCorruptDataNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notif) {
        
        NSLog(@"[AppDelegate] kMXSessionDidCorruptDataNotification received. Reload the app");
        
        // Reload entirely the app when a session has corrupted its data
        [[AppDelegate theDelegate] reloadMatrixSessions:YES];
        
    }];
    
    // Add observer on settings changes.
    [[MXKAppSettings standardAppSettings] addObserver:self forKeyPath:@"showAllEventsInRoomHistory" options:0 context:nil];
    
    // Prepare account manager
    MXKAccountManager *accountManager = [MXKAccountManager sharedManager];
    
    // Use MXFileStore as MXStore to permanently store events.
    accountManager.storeClass = [MXFileStore class];
    
    // Observers have been defined, we can start a matrix session for each enabled accounts.
    // except if the app is still in background.
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground)
    {
        NSLog(@"[AppDelegate] initMatrixSessions: prepareSessionForActiveAccounts");
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
        for (MXKAccount *account in mxAccounts)
        {
            // Replace default room summary updater
            EventFormatter *eventFormatter = [[EventFormatter alloc] initWithMatrixSession:account.mxSession];
            eventFormatter.isForSubtitle = YES;
            account.mxSession.roomSummaryUpdateDelegate = eventFormatter;
            
            // The push gateway url is now configurable.
            // Set this url in the existing accounts when it is undefined.
            if (!account.pushGatewayURL)
            {
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
        [_masterTabBarController addMatrixSession:mxSession];

        // Register the session to the widgets manager
        [[WidgetManager sharedManager] addMatrixSession:mxSession];
        
        [mxSessionArray addObject:mxSession];
        
        // Do the one time check on device id
        [self checkDeviceId:mxSession];
    }
}

- (void)removeMatrixSession:(MXSession*)mxSession
{
    [[MXKContactManager sharedManager] removeMatrixSession:mxSession];
    
    // Update home data sources
    [_masterTabBarController removeMatrixSession:mxSession];

    // Update the widgets manager
    [[WidgetManager sharedManager] removeMatrixSession:mxSession]; 
    
    // If any, disable the no VoIP support workaround
    [self disableNoVoIPOnMatrixSession:mxSession];
    
    [mxSessionArray removeObject:mxSession];
}

- (void)markAllMessagesAsRead
{
    for (MXSession *session in mxSessionArray)
    {
        [session markAllMessagesAsRead];
    }
}

- (void)reloadMatrixSessions:(BOOL)clearCache
{
    // Reload all running matrix sessions
    NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    for (MXKAccount *account in mxAccounts)
    {
        [account reload:clearCache];
        
        // Replace default room summary updater
        EventFormatter *eventFormatter = [[EventFormatter alloc] initWithMatrixSession:account.mxSession];
        eventFormatter.isForSubtitle = YES;
        account.mxSession.roomSummaryUpdateDelegate = eventFormatter;
    }
    
    // Force back to Recents list if room details is displayed (Room details are not available until the end of initial sync)
    [self popToHomeViewControllerAnimated:NO completion:nil];
    
    if (clearCache)
    {
        // clear the media cache
        [MXMediaManager clearCache];
    }
}

- (void)logout
{
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    isAPNSRegistered = NO;
    
    // Clear cache
    [MXMediaManager clearCache];
    
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
    [_masterTabBarController showAuthenticationScreen];
    
    // Note: Keep App settings
    
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
    matrixCallObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallManagerNewCall object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        // Ignore the call if a call is already in progress
        if (!currentCallViewController && !_jitsiViewController)
        {
            MXCall *mxCall = (MXCall*)notif.object;
            
            // Prepare the call view controller
            currentCallViewController = [CallViewController callViewController:mxCall];
            currentCallViewController.delegate = self;
            
            [self presentCallViewController:nil];
        }
    }];
}

- (void)handleLaunchAnimation
{
    MXSession *mainSession = self.mxSessions.firstObject;
    
    if (mainSession)
    {
        BOOL isLaunching = NO;
        
        switch (mainSession.state)
        {
            case MXSessionStateClosed:
            case MXSessionStateInitialised:
                isLaunching = YES;
                break;
            case MXSessionStateStoreDataReady:
            case MXSessionStateSyncInProgress:
                // Stay in launching during the first server sync if the store is empty.
                isLaunching = (mainSession.rooms.count == 0 && launchAnimationContainerView);
            default:
                break;
        }
        
        if (isLaunching)
        {
            UIWindow *window = [[UIApplication sharedApplication] keyWindow];
            
            if (!launchAnimationContainerView && window)
            {
                launchAnimationContainerView = [[UIView alloc] initWithFrame:window.bounds];
                launchAnimationContainerView.backgroundColor = kRiotPrimaryBgColor;
                launchAnimationContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                [window addSubview:launchAnimationContainerView];
                
                // Add animation view
                UIImageView *animationView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 170, 170)];
                animationView.image = [UIImage animatedImageNamed:@"animatedLogo-" duration:2];
                
                animationView.center = CGPointMake(launchAnimationContainerView.center.x, 3 * launchAnimationContainerView.center.y / 4);
                
                animationView.translatesAutoresizingMaskIntoConstraints = NO;
                [launchAnimationContainerView addSubview:animationView];
                
                NSLayoutConstraint* widthConstraint = [NSLayoutConstraint constraintWithItem:animationView
                                                                                   attribute:NSLayoutAttributeWidth
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:nil
                                                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                                                  multiplier:1
                                                                                    constant:170];
                
                NSLayoutConstraint* heightConstraint = [NSLayoutConstraint constraintWithItem:animationView
                                                                                    attribute:NSLayoutAttributeHeight
                                                                                    relatedBy:NSLayoutRelationEqual
                                                                                       toItem:nil
                                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                                   multiplier:1
                                                                                     constant:170];
                
                NSLayoutConstraint* centerXConstraint = [NSLayoutConstraint constraintWithItem:animationView
                                                                                     attribute:NSLayoutAttributeCenterX
                                                                                     relatedBy:NSLayoutRelationEqual
                                                                                        toItem:launchAnimationContainerView
                                                                                     attribute:NSLayoutAttributeCenterX
                                                                                    multiplier:1
                                                                                      constant:0];
                
                NSLayoutConstraint* centerYConstraint = [NSLayoutConstraint constraintWithItem:animationView
                                                                                     attribute:NSLayoutAttributeCenterY
                                                                                     relatedBy:NSLayoutRelationEqual
                                                                                        toItem:launchAnimationContainerView
                                                                                     attribute:NSLayoutAttributeCenterY
                                                                                    multiplier:3.0/4.0
                                                                                      constant:0];
                
                [NSLayoutConstraint activateConstraints:@[widthConstraint, heightConstraint, centerXConstraint, centerYConstraint]];
                
                
                // In addition, show a spinner under this giffy animation
                UIActivityIndicatorView* activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
                activityIndicator.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
                activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
                activityIndicator.hidesWhenStopped = YES;
                
                CGRect frame = activityIndicator.frame;
                frame.size.width += 30;
                frame.size.height += 30;
                activityIndicator.bounds = frame;
                [activityIndicator.layer setCornerRadius:5];
                
                activityIndicator.center = CGPointMake(launchAnimationContainerView.center.x, 6 * launchAnimationContainerView.center.y / 4);
                [launchAnimationContainerView addSubview:activityIndicator];
                
                activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
                
                NSLayoutConstraint* widthConstraint2 = [NSLayoutConstraint constraintWithItem:activityIndicator
                                                                                    attribute:NSLayoutAttributeWidth
                                                                                    relatedBy:NSLayoutRelationEqual
                                                                                       toItem:nil
                                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                                   multiplier:1
                                                                                     constant:frame.size.width];
                
                NSLayoutConstraint* heightConstraint2 = [NSLayoutConstraint constraintWithItem:activityIndicator
                                                                                     attribute:NSLayoutAttributeHeight
                                                                                     relatedBy:NSLayoutRelationEqual
                                                                                        toItem:nil
                                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                                    multiplier:1
                                                                                      constant:frame.size.height];
                
                NSLayoutConstraint* centerXConstraint2 = [NSLayoutConstraint constraintWithItem:activityIndicator
                                                                                      attribute:NSLayoutAttributeCenterX
                                                                                      relatedBy:NSLayoutRelationEqual
                                                                                         toItem:launchAnimationContainerView
                                                                                      attribute:NSLayoutAttributeCenterX
                                                                                     multiplier:1
                                                                                       constant:0];
                
                NSLayoutConstraint* centerYConstraint2 = [NSLayoutConstraint constraintWithItem:activityIndicator
                                                                                      attribute:NSLayoutAttributeCenterY
                                                                                      relatedBy:NSLayoutRelationEqual
                                                                                         toItem:launchAnimationContainerView
                                                                                      attribute:NSLayoutAttributeCenterY
                                                                                     multiplier:6.0/4.0
                                                                                       constant:0];
                
                [NSLayoutConstraint activateConstraints:@[widthConstraint2, heightConstraint2, centerXConstraint2, centerYConstraint2]];
                
                [activityIndicator startAnimating];
                
                launchAnimationStart = [NSDate date];
            }
            
            return;
        }
    }
    
    if (launchAnimationContainerView)
    {
        NSTimeInterval durationMs = [[NSDate date] timeIntervalSinceDate:launchAnimationStart] * 1000;
        NSLog(@"[AppDelegate] LaunchAnimation was shown for %.3fms", durationMs);
        
        if ([MXSDKOptions sharedInstance].enableGoogleAnalytics)
        {
            id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
            [tracker send:[[GAIDictionaryBuilder createTimingWithCategory:kMXGoogleAnalyticsStartupCategory
                                                                 interval:@((int)durationMs)
                                                                     name:kMXGoogleAnalyticsStartupLaunchScreen
                                                                    label:nil] build]];
        }
        
        [launchAnimationContainerView removeFromSuperview];
        launchAnimationContainerView = nil;
    }
}

#pragma mark -

/**
 Check the existence of device id.
 */
- (void)checkDeviceId:(MXSession*)mxSession
{
    // In case of the app update for the e2e encryption, the app starts with
    // no device id provided by the homeserver.
    // Ask the user to login again in order to enable e2e. Ask it once
    if (!isErrorNotificationSuspended && ![[NSUserDefaults standardUserDefaults] boolForKey:@"deviceIdAtStartupChecked"])
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"deviceIdAtStartupChecked"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // Check if there is a device id
        if (!mxSession.matrixRestClient.credentials.deviceId)
        {
            NSLog(@"WARNING: The user has no device. Prompt for login again");
            
            NSString *msg = NSLocalizedStringFromTable(@"e2e_enabling_on_app_update", @"Vector", nil);
            
            __weak typeof(self) weakSelf = self;
            [_errorNotification dismissViewControllerAnimated:NO completion:nil];
            _errorNotification = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
            
            [_errorNotification addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"later"]
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                     
                                                                     if (weakSelf)
                                                                     {
                                                                         typeof(self) self = weakSelf;
                                                                         self->_errorNotification = nil;
                                                                     }
                                                                     
                                                                 }]];
            
            [_errorNotification addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                     
                                                                     if (weakSelf)
                                                                     {
                                                                         typeof(self) self = weakSelf;
                                                                         self->_errorNotification = nil;
                                                                         
                                                                         [self logout];
                                                                     }
                                                                     
                                                                 }]];
            
            // Prompt the user
            [_errorNotification mxk_setAccessibilityIdentifier:@"AppDelegateErrorAlert"];
            [self showNotificationAlert:_errorNotification];
        }
    }
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
                            [self.mxInAppNotification dismissViewControllerAnimated:NO completion:nil];
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
                        self.mxInAppNotification = [UIAlertController alertControllerWithTitle:roomState.displayname
                                                                                       message:messageText
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        
                        [self.mxInAppNotification addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                                                     style:UIAlertActionStyleDefault
                                                                                   handler:^(UIAlertAction * action) {
                                                                                       
                                                                                       if (weakSelf)
                                                                                       {
                                                                                           typeof(self) self = weakSelf;
                                                                                           self.mxInAppNotification = nil;
                                                                                           [account updateNotificationListenerForRoomId:event.roomId ignore:YES];
                                                                                       }
                                                                                       
                                                                                   }]];
                        
                        [self.mxInAppNotification addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"view", @"Vector", nil)
                                                                                     style:UIAlertActionStyleDefault
                                                                                   handler:^(UIAlertAction * action) {
                                                                                       
                                                                                       if (weakSelf)
                                                                                       {
                                                                                           typeof(self) self = weakSelf;
                                                                                           self.mxInAppNotification = nil;
                                                                                           // Show the room
                                                                                           [self showRoom:event.roomId andEventId:nil withMatrixSession:account.mxSession];
                                                                                       }
                                                                                       
                                                                                   }]];
                        
                        [self.window.rootViewController presentViewController:self.mxInAppNotification animated:YES completion:nil];
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
        [self.mxInAppNotification dismissViewControllerAnimated:NO completion:nil];
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
        [accountPicker dismissViewControllerAnimated:NO completion:nil];
        
        accountPicker = [UIAlertController alertControllerWithTitle:[NSBundle mxk_localizedStringForKey:@"select_account"] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        __weak typeof(self) weakSelf = self;
        for(MXKAccount *account in mxAccounts)
        {
            [accountPicker addAction:[UIAlertAction actionWithTitle:account.mxCredentials.userId
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
                                                                
                                                                if (weakSelf)
                                                                {
                                                                    typeof(self) self = weakSelf;
                                                                    self->accountPicker = nil;
                                                                    
                                                                    if (onSelection)
                                                                    {
                                                                        onSelection(account);
                                                                    }
                                                                }
                                                                
                                                            }]];
        }
        
        [accountPicker addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action) {
                                                            
                                                            if (weakSelf)
                                                            {
                                                                typeof(self) self = weakSelf;
                                                                self->accountPicker = nil;
                                                                
                                                                if (onSelection)
                                                                {
                                                                    onSelection(nil);
                                                                }
                                                            }
                                                            
                                                        }]];
        
        [self showNotificationAlert:accountPicker];
    }
}

#pragma mark - Matrix Rooms handling

- (void)showRoom:(NSString*)roomId andEventId:(NSString*)eventId withMatrixSession:(MXSession*)mxSession
{
    [self restoreInitialDisplay:^{
        
        // Select room to display its details (dispatch this action in order to let TabBarController end its refresh)
        [_masterTabBarController selectRoomWithId:roomId andEventId:eventId inMatrixSession:mxSession];
        
    }];
}

- (void)showRoomPreview:(RoomPreviewData*)roomPreviewData
{
    [self restoreInitialDisplay:^{
        
        [_masterTabBarController showRoomPreview:roomPreviewData];
        
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

- (void)createDirectChatWithUserId:(NSString*)userId completion:(void (^)(void))completion
{
    // Handle here potential multiple accounts
    [self selectMatrixAccount:^(MXKAccount *selectedAccount) {
        
        MXSession *mxSession = selectedAccount.mxSession;
        
        if (mxSession)
        {
            // Create a new room by inviting the other user only if it is defined and not oneself
            NSArray *invite = ((userId && ![mxSession.myUser.userId isEqualToString:userId]) ? @[userId] : nil);
            
            [mxSession createRoom:nil
                       visibility:kMXRoomDirectoryVisibilityPrivate
                        roomAlias:nil
                            topic:nil
                           invite:invite
                       invite3PID:nil
                         isDirect:(invite.count != 0)
                           preset:kMXRoomPresetTrustedPrivateChat
                          success:^(MXRoom *room) {
                              
                              // Open created room
                              [self showRoom:room.state.roomId andEventId:nil withMatrixSession:mxSession];
                              
                              if (completion)
                              {
                                  completion();
                              }
                              
                          }
                          failure:^(NSError *error) {
                              
                              NSLog(@"[AppDelegate] Create direct chat failed");
                              //Alert user
                              [self showErrorAsAlert:error];
                              
                              if (completion)
                              {
                                  completion();
                              }
                              
                          }];
        }
        else if (completion)
        {
            completion();
        }
        
    }];
}

- (void)startDirectChatWithUserId:(NSString*)userId completion:(void (^)(void))completion
{
    // Handle here potential multiple accounts
    [self selectMatrixAccount:^(MXKAccount *selectedAccount) {
        
        MXSession *mxSession = selectedAccount.mxSession;
        
        if (mxSession)
        {
            MXRoom *directRoom = [mxSession directJoinedRoomWithUserId:userId];
            
            // if the room exists
            if (directRoom)
            {
                // open it
                [self showRoom:directRoom.roomId andEventId:nil withMatrixSession:mxSession];
                
                if (completion)
                {
                    completion();
                }
            }
            else
            {
                [self createDirectChatWithUserId:userId completion:completion];
            }
        }
        else if (completion)
        {
            completion();
        }
        
    }];
}

#pragma mark - Contacts handling

- (void)showContact:(MXKContact*)contact
{
    [self restoreInitialDisplay:^{

        [self.masterTabBarController selectContact:contact];

    }];
}

- (void)refreshLocalContacts
{
    // Check whether the application is allowed to access the local contacts.
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
    {
        // Check the user permission for syncing local contacts. This permission was handled independently on previous application version.
        if (![MXKAppSettings standardAppSettings].syncLocalContacts)
        {
            // Check whether it was not requested yet.
            if (![MXKAppSettings standardAppSettings].syncLocalContactsPermissionRequested)
            {
                [MXKAppSettings standardAppSettings].syncLocalContactsPermissionRequested = YES;
                
                UIViewController *viewController = self.window.rootViewController.presentedViewController;
                if (!viewController)
                {
                    viewController = self.window.rootViewController;
                }
                
                [MXKContactManager requestUserConfirmationForLocalContactsSyncInViewController:viewController completionHandler:^(BOOL granted) {
                    
                    if (granted)
                    {
                        // Allow local contacts sync in order to discover matrix users.
                        [MXKAppSettings standardAppSettings].syncLocalContacts = YES;
                    }
                    
                }];
            }
        }
        
        // Refresh the local contacts list.
        [[MXKContactManager sharedManager] refreshLocalContacts];
    }
}

#pragma mark - MXKCallViewControllerDelegate

- (void)dismissCallViewController:(MXKCallViewController *)callViewController completion:(void (^)())completion
{
    if (currentCallViewController && callViewController == currentCallViewController)
    {
        if (_incomingCallNotification)
        {
            // The user was prompted for an incoming call which ended
            // The call view controller was not presented yet.
            [_incomingCallNotification dismissViewControllerAnimated:NO completion:nil];
            _incomingCallNotification = nil;
            
            // Release properly
            [currentCallViewController destroy];
            currentCallViewController = nil;
            
            if (completion)
            {
                completion();
            }
        }
        else if (callViewController.isBeingPresented)
        {
            // Here the presentation of the call view controller is in progress
            // Postpone the dismiss
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self dismissCallViewController:callViewController completion:completion];
            });
        }
        // Check whether the call view controller is actually presented
        else if (callViewController.presentingViewController)
        {
            BOOL callIsEnded = (callViewController.mxCall.state == MXCallStateEnded);
            NSLog(@"Call view controller is dismissed (%d)", callIsEnded);
            
            [callViewController dismissViewControllerAnimated:YES completion:^{
                
                if (!callIsEnded)
                {
                    NSString *btnTitle = [NSString stringWithFormat:NSLocalizedStringFromTable(@"active_call_details", @"Vector", nil), callViewController.callerNameLabel.text];
                    [self addCallStatusBar:btnTitle];
                }
                
                if (completion)
                {
                    completion();
                }
                
            }];
            
            if (callIsEnded)
            {
                [self removeCallStatusBar];
                
                // Release properly
                [currentCallViewController destroy];
                currentCallViewController = nil;
            }
        }
        else
        {
            // Here the call view controller was not presented.
            NSLog(@"Call view controller was not presented");
            
            // Workaround to manage the "back to call" banner: present temporarily the call screen.
            // This will correctly manage the navigation bar layout.
            [self presentCallViewController:^{
                
                [self dismissCallViewController:currentCallViewController completion:completion];
                
            }];
        }
    }
}

#pragma mark - Jitsi call

- (void)displayJitsiViewControllerWithWidget:(Widget*)jitsiWidget andVideo:(BOOL)video
{
    if (!_jitsiViewController && !currentCallViewController)
    {
        _jitsiViewController = [JitsiViewController jitsiViewController];

        if ([_jitsiViewController openWidget:jitsiWidget withVideo:video])
        {
            _jitsiViewController.delegate = self;
            [self presentJitsiViewController:nil];
        }
        else
        {
            _jitsiViewController = nil;

            NSError *error = [NSError errorWithDomain:@""
                                                 code:0
                                             userInfo:@{
                                                        NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"call_jitsi_error", @"Vector", nil)
                                                        }];
            [self showErrorAsAlert:error];
        }
    }
    else
    {
        NSError *error = [NSError errorWithDomain:@""
                                    code:0
                                userInfo:@{
                                           NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"call_already_displayed", @"Vector", nil)
                                           }];
        [self showErrorAsAlert:error];
    }
}

- (void)presentJitsiViewController:(void (^)())completion
{
    [self removeCallStatusBar];

    if (_jitsiViewController)
    {
        if (self.window.rootViewController.presentedViewController)
        {
            [self.window.rootViewController.presentedViewController presentViewController:_jitsiViewController animated:YES completion:completion];
        }
        else
        {
            [self.window.rootViewController presentViewController:_jitsiViewController animated:YES completion:completion];
        }
    }
}

- (void)jitsiViewController:(JitsiViewController *)jitsiViewController dismissViewJitsiController:(void (^)())completion
{
    if (jitsiViewController == _jitsiViewController)
    {
        [_jitsiViewController dismissViewControllerAnimated:YES completion:completion];
        _jitsiViewController = nil;

        [self removeCallStatusBar];
    }
}

- (void)jitsiViewController:(JitsiViewController *)jitsiViewController goBackToApp:(void (^)())completion
{
    if (jitsiViewController == _jitsiViewController)
    {
        [_jitsiViewController dismissViewControllerAnimated:YES completion:^{

            MXRoom *room = [_jitsiViewController.widget.mxSession roomWithRoomId:_jitsiViewController.widget.roomId];
            NSString *btnTitle = [NSString stringWithFormat:NSLocalizedStringFromTable(@"active_call_details", @"Vector", nil), room.riotDisplayname];
            [self addCallStatusBar:btnTitle];

            if (completion)
            {
                completion();
            }
        }];
    }
}


#pragma mark - Call status handling

- (void)addCallStatusBar:(NSString*)buttonTitle
{
    // Add a call status bar
    CGSize topBarSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width, CALL_STATUS_BAR_HEIGHT);
    
    _callStatusBarWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, topBarSize.width, topBarSize.height)];
    _callStatusBarWindow.windowLevel = UIWindowLevelStatusBar;
    
    // Create statusBarButton
    _callStatusBarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _callStatusBarButton.frame = CGRectMake(0, 0, topBarSize.width, topBarSize.height);
    
    [_callStatusBarButton setTitle:buttonTitle forState:UIControlStateNormal];
    [_callStatusBarButton setTitle:buttonTitle forState:UIControlStateHighlighted];
    _callStatusBarButton.titleLabel.textColor = kRiotPrimaryBgColor;
    
    if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)])
    {
        _callStatusBarButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    }
    else
    {
        _callStatusBarButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    }
    
    [_callStatusBarButton setBackgroundColor:kRiotColorGreen];
    [_callStatusBarButton addTarget:self action:@selector(onCallStatusBarButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    // Place button into the new window
    [_callStatusBarButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_callStatusBarWindow addSubview:_callStatusBarButton];
    
    // Force callStatusBarButton to fill the window (to handle auto-layout in case of screen rotation)
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:_callStatusBarButton
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:_callStatusBarWindow
                                                                       attribute:NSLayoutAttributeWidth
                                                                      multiplier:1.0
                                                                        constant:0];
    
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:_callStatusBarButton
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_callStatusBarWindow
                                                                        attribute:NSLayoutAttributeHeight
                                                                       multiplier:1.0
                                                                         constant:0];
    
    [NSLayoutConstraint activateConstraints:@[widthConstraint, heightConstraint]];
    
    _callStatusBarWindow.hidden = NO;
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
    if (_callStatusBarWindow)
    {
        // No more need to listen to system status bar changes
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
        
        // Hide & destroy it
        _callStatusBarWindow.hidden = YES;
        [_callStatusBarButton removeFromSuperview];
        _callStatusBarButton = nil;
        _callStatusBarWindow = nil;
        
        [self statusBarDidChangeFrame];
    }
}

- (void)onCallStatusBarButtonPressed
{
    if (currentCallViewController)
    {
        [self presentCallViewController:nil];
    }
    else if (_jitsiViewController)
    {
        [self presentJitsiViewController:nil];
    }
}

- (void)presentCallViewController:(void (^)())completion
{
    [self removeCallStatusBar];
    
    if (currentCallViewController)
    {
        if (self.window.rootViewController.presentedViewController)
        {
            [self.window.rootViewController.presentedViewController presentViewController:currentCallViewController animated:YES completion:completion];
        }
        else
        {
            [self.window.rootViewController presentViewController:currentCallViewController animated:YES completion:completion];
        }
    }
}

- (void)statusBarDidChangeFrame
{
    UIApplication *app = [UIApplication sharedApplication];
    UIViewController *rootController = app.keyWindow.rootViewController;
    
    // Refresh the root view controller frame
    CGRect rootControllerFrame = [[UIScreen mainScreen] bounds];
    
    if (_callStatusBarWindow)
    {
        UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
        
        switch (statusBarOrientation)
        {
            case UIInterfaceOrientationLandscapeLeft:
            {
                _callStatusBarWindow.frame = CGRectMake(-rootControllerFrame.size.width / 2, -CALL_STATUS_BAR_HEIGHT / 2, rootControllerFrame.size.width, CALL_STATUS_BAR_HEIGHT);
                _callStatusBarWindow.transform = CGAffineTransformMake(0, -1, 1, 0, CALL_STATUS_BAR_HEIGHT / 2, rootControllerFrame.size.width / 2);
                break;
            }
            case UIInterfaceOrientationLandscapeRight:
            {
                _callStatusBarWindow.frame = CGRectMake(-rootControllerFrame.size.width / 2, -CALL_STATUS_BAR_HEIGHT / 2, rootControllerFrame.size.width, CALL_STATUS_BAR_HEIGHT);
                _callStatusBarWindow.transform = CGAffineTransformMake(0, 1, -1, 0, rootControllerFrame.size.height - CALL_STATUS_BAR_HEIGHT / 2, rootControllerFrame.size.width / 2);
                break;
            }
            default:
            {
                _callStatusBarWindow.transform = CGAffineTransformIdentity;
                _callStatusBarWindow.frame = CGRectMake(0, 0, rootControllerFrame.size.width, CALL_STATUS_BAR_HEIGHT);
                break;
            }
        }
        
        // Apply the vertical offset due to call status bar
        rootControllerFrame.origin.y = CALL_STATUS_BAR_HEIGHT;
        rootControllerFrame.size.height -= CALL_STATUS_BAR_HEIGHT;
    }
    
    rootController.view.frame = rootControllerFrame;
    if (rootController.presentedViewController)
    {
        rootController.presentedViewController.view.frame = rootControllerFrame;
    }
    [rootController.view setNeedsLayout];
}

#pragma mark - SplitViewController delegate

- (nullable UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController
{
    // Return the top view controller of the master navigation controller, if it is a navigation controller itself.
    UIViewController *topViewController = _masterNavigationController.topViewController;
    if ([topViewController isKindOfClass:UINavigationController.class])
    {
        return topViewController;
    }
    
    // Else return the default empty details view controller from the storyboard.
    // Be sure that the primary is then visible too.
    if (splitViewController.displayMode == UISplitViewControllerDisplayModePrimaryHidden)
    {
        splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    }
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    UIViewController *emptyDetailsViewController = [storyboard instantiateViewControllerWithIdentifier:@"EmptyDetailsViewControllerStoryboardId"];
    emptyDetailsViewController.view.backgroundColor = kRiotPrimaryBgColor;
    return emptyDetailsViewController;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController
{
    if (!self.masterTabBarController.currentRoomViewController && !self.masterTabBarController.currentContactDetailViewController)
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
                             onEvent:^(MXEvent *event, MXTimelineDirection direction, id customObject) {
                                 
                                 if (MXTimelineDirectionForwards == direction)
                                 {
                                     switch (event.eventType)
                                     {
                                         case MXEventTypeCallInvite:
                                         {
                                             if (noCallSupportAlert)
                                             {
                                                 [noCallSupportAlert dismissViewControllerAnimated:NO completion:nil];
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
                                             
                                             NSString *appDisplayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
                                             
                                             NSString *message = [NSString stringWithFormat:NSLocalizedStringFromTable(@"no_voip", @"Vector", nil), callerDisplayname, appDisplayName];
                                             
                                             noCallSupportAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"no_voip_title", @"Vector", nil)
                                                                                                      message:message
                                                                                               preferredStyle:UIAlertControllerStyleAlert];
                                             
                                             __weak typeof(self) weakSelf = self;
                                             
                                             [noCallSupportAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ignore"]
                                                                                                    style:UIAlertActionStyleDefault
                                                                                                  handler:^(UIAlertAction * action) {
                                                                                                      
                                                                                                      if (weakSelf)
                                                                                                      {
                                                                                                          typeof(self) self = weakSelf;
                                                                                                          self->noCallSupportAlert = nil;
                                                                                                      }
                                                                                                      
                                                                                                  }]];
                                             
                                             [noCallSupportAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"reject_call"]
                                                                                                    style:UIAlertActionStyleDefault
                                                                                                  handler:^(UIAlertAction * action) {
                                                                                                      
                                                                                                      // Reject the call by sending the hangup event
                                                                                                      NSDictionary *content = @{
                                                                                                                                @"call_id": callInviteEventContent.callId,
                                                                                                                                @"version": @(0)
                                                                                                                                };
                                                                                                      
                                                                                                      [mxSession.matrixRestClient sendEventToRoom:event.roomId eventType:kMXEventTypeStringCallHangup content:content success:nil failure:^(NSError *error) {
                                                                                                          NSLog(@"[AppDelegate] enableNoVoIPOnMatrixSession: ERROR: Cannot send m.call.hangup event.");
                                                                                                      }];
                                                                                                      
                                                                                                      if (weakSelf)
                                                                                                      {
                                                                                                          typeof(self) self = weakSelf;
                                                                                                          self->noCallSupportAlert = nil;
                                                                                                      }
                                                                                                      
                                                                                                  }]];
                                             
                                             [self showNotificationAlert:noCallSupportAlert];
                                             break;
                                         }
                                             
                                         case MXEventTypeCallAnswer:
                                         case MXEventTypeCallHangup:
                                             // The call has ended. The alert is no more needed.
                                             if (noCallSupportAlert)
                                             {
                                                 [noCallSupportAlert dismissViewControllerAnimated:YES completion:nil];
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
