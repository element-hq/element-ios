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
#import "RoomViewController.h"
#import "SettingsViewController.h"
#import "MXKContactManager.h"
#import "RageShakeManager.h"

#import "NSBundle+MatrixKit.h"

#import "AFNetworkReachabilityManager.h"

#import <AudioToolbox/AudioToolbox.h>

//#define MX_CALL_STACK_OPENWEBRTC
#ifdef MX_CALL_STACK_OPENWEBRTC
#import <MatrixOpenWebRTCWrapper/MatrixOpenWebRTCWrapper.h>
#endif

#ifdef MX_CALL_STACK_ENDPOINT
#import <MatrixEndpointWrapper/MatrixEndpointWrapper.h>
#endif

#define MAKE_STRING(x) #x
#define MAKE_NS_STRING(x) @MAKE_STRING(x)

@interface AppDelegate () <UISplitViewControllerDelegate>
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
            _build = buildBranch ? buildBranch : NSLocalizedStringFromTable(@"settings_config_no_build_info", @"MatrixConsole", nil);
        }
    }
    return _build;
}

- (void)setIsOffline:(BOOL)isOffline
{
    if (isOffline)
    {
        // Add observer to leave this state automatically.
        reachabilityObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AFNetworkingReachabilityDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            
            NSNumber *statusItem = note.userInfo[AFNetworkingReachabilityNotificationStatusItem];
            if (statusItem)
            {
                AFNetworkReachabilityStatus reachabilityStatus = statusItem.integerValue;
                if (reachabilityStatus == AFNetworkReachabilityStatusReachableViaWiFi || reachabilityStatus == AFNetworkReachabilityStatusReachableViaWWAN)
                {
                    self.isOffline = NO;
                }
            }
            
        }];
    }
    else
    {
        // Release potential observer
        if (reachabilityObserver)
        {
            [[NSNotificationCenter defaultCenter] removeObserver:reachabilityObserver];
            reachabilityObserver = nil;
        }
    }
    
    _isOffline = isOffline;
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    if ([self.window.rootViewController isKindOfClass:[MasterTabBarController class]])
    {
        self.masterTabBarController = (MasterTabBarController*)self.window.rootViewController;
        self.masterTabBarController.delegate = self;
        
        // By default the "Home" tab is focused
        [self.masterTabBarController setSelectedIndex:TABBAR_HOME_INDEX];
        
        UIViewController* recents = [self.masterTabBarController.viewControllers objectAtIndex:TABBAR_RECENTS_INDEX];
        if ([recents isKindOfClass:[UISplitViewController class]])
        {
            UISplitViewController *splitViewController = (UISplitViewController *)recents;
            UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
            
            // IOS >= 8
            if ([splitViewController respondsToSelector:@selector(displayModeButtonItem)])
            {
                navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
                
                // on IOS 8 iPad devices, force to display the primary and the secondary viewcontroller
                // to avoid empty room View Controller in portrait orientation
                // else, the user cannot select a room
                // shouldHideViewController delegate method is also implemented
                if ([splitViewController respondsToSelector:@selector(preferredDisplayMode)] && [(NSString*)[UIDevice currentDevice].model hasPrefix:@"iPad"])
                {
                    splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
                }
            }
            
            splitViewController.delegate = self;
        }
        else
        {
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
        
        // Add matrix observers and initialize matrix sessions.
        [self initMatrixSessions];
    }
    
    // clear the notifications counter
    [self clearNotifications];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
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
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    // Stop reachability monitoring
    self.isOffline = NO;
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
    
    // check if some media must be released to reduce the cache size
    [MXKMediaManager reduceCacheSizeToInsert:0];
    
    // Hide potential notification
    if (self.mxInAppNotification)
    {
        [self.mxInAppNotification dismiss:NO];
        self.mxInAppNotification = nil;
    }
    
    // Suspend all running matrix sessions
    NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    for (MXKAccount *account in mxAccounts)
    {
        [account pauseInBackgroundTask];
    }
    
    // clear the notifications counter
    [self clearNotifications];
    
    _isAppForeground = NO;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    // clear the notifications counter
    [self clearNotifications];
    
    _isAppForeground = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    // Start monitoring reachability
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
    
    // check if the app crashed last time
    if ([MXLogger crashLog])
    {
        [[RageShakeManager sharedManager] promptCrashReportInViewController:self.masterTabBarController.selectedViewController];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - APNS methods

- (void)registerUserNotificationSettings
{
    if (!isAPNSRegistered)
    {
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)])
        {
            // Registration on iOS 8 and later
            UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
                                                                                                 |UIRemoteNotificationTypeSound
                                                                                                 |UIRemoteNotificationTypeAlert) categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        } else
        {
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationType)(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge)];
        }
    }
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication*)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    NSLog(@"[AppDelegate] Got APNS token!");
    
    MXKAccountManager* accountManager = [MXKAccountManager sharedManager];
    [accountManager setApnsDeviceToken:deviceToken];
    
    // force send the push token once per app start
    if (!isAPNSRegistered)
    {
        NSArray *mxAccounts = accountManager.activeAccounts;
        for (MXKAccount *account in mxAccounts)
        {
            account.enablePushNotifications = YES;
        }
    }
    isAPNSRegistered = YES;
}

- (void)application:(UIApplication*)app didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"[AppDelegate] Failed to register for APNS: %@", error);
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
#ifdef DEBUG
    // log the full userInfo only in DEBUG
    NSLog(@"[AppDelegate] APNS: %@", userInfo);
#endif
    
    completionHandler(UIBackgroundFetchResultNoData);
    
    // Jump to the concerned room only if the app is transitioning from the background
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive)
    {
        // Look for the room id
        NSString* roomId = [userInfo objectForKey:@"room_id"];
        if (roomId.length)
        {
            // TODO retrieve the right matrix session
            
            //**************
            // Patch consider the first session which knows the room id
            MXSession *mxSession;
            NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
            
            if (mxAccounts.count == 1)
            {
                MXKAccount *account = mxAccounts.firstObject;
                mxSession = account.mxSession;
            } else
            {
                for (MXKAccount *account in mxAccounts)
                {
                    if ([account.mxSession roomWithRoomId:roomId])
                    {
                        mxSession = account.mxSession;
                        break;
                    }
                }
            }
            //**************
            
            
            [self.masterTabBarController showRoom:roomId withMatrixSession:mxSession];
        }
    }
}

#pragma mark - Matrix sessions handling

- (void)initMatrixSessions
{
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
            // Report this session to contact manager
            [[MXKContactManager sharedManager] addMatrixSession:mxSession];
            
            // Update all view controllers thanks to tab bar controller
            [self.masterTabBarController addMatrixSession:mxSession];
            
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
            [[MXKContactManager sharedManager] removeMatrixSession:mxSession];
            [self.masterTabBarController removeMatrixSession:mxSession];
        }
        
        // Restore call observer only if all session are running
        NSArray *mxSessions = self.masterTabBarController.mxSessions;
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
        
        // Launch matrix session for this new account
        MXKAccount *account = notif.object;
        if (account)
        {
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
    
    // Observe settings changes
    [[MXKAppSettings standardAppSettings]  addObserver:self forKeyPath:@"showAllEventsInRoomHistory" options:0 context:nil];
    
    // Prepare account manager
    MXKAccountManager *accountManager = [MXKAccountManager sharedManager];
    
    // Use MXFileStore as MXStore to permanently store events.
    accountManager.storeClass = [MXFileStore class];

    // Observers have been defined, we start now a matrix session for each enabled accounts.
    [accountManager openSessionForActiveAccounts];

    // Set the VoIP call stack
    for (MXKAccount *account in accountManager.accounts)
    {
        id<MXCallStack> callStack;

#ifdef MX_CALL_STACK_OPENWEBRTC
        callStack = [[MXOpenWebRTCCallStack alloc] init];
#endif
#ifdef MX_CALL_STACK_ENDPOINT
        callStack = [[MXEndpointCallStack alloc] initWithMatrixId:account.mxSession.myUser.userId];
#endif
        if (callStack)
        {
            [account.mxSession enableVoIPWithCallStack:callStack];
        }
    }
    
    // Check whether we're already logged in
    NSArray *mxAccounts = accountManager.accounts;
    if (mxAccounts.count)
    {
        // Set up push notifications
        [self registerUserNotificationSettings];
        
        // When user is already logged, we launch the app on Recents
        [self.masterTabBarController setSelectedIndex:TABBAR_RECENTS_INDEX];
        
        // Observe inApp notifications toggle change for each account
        for (MXKAccount *account in mxAccounts)
        {
            [account addObserver:self forKeyPath:@"enableInAppNotifications" options:0 context:nil];
        }
    }
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
    [self.masterTabBarController popRoomViewControllerAnimated:NO];
    
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
    [self.masterTabBarController showAuthenticationScreen];
    
    // Reset App settings
    [[MXKAppSettings standardAppSettings] reset];
    
    // Reset the contact manager
    [[MXKContactManager sharedManager] reset];
    
    // By default the "Home" tab is focussed
    [self.masterTabBarController setSelectedIndex:TABBAR_HOME_INDEX];
}

- (MXKAlert*)showErrorAsAlert:(NSError*)error
{
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
    if (!title)
    {
        title = [NSBundle mxk_localizedStringForKey:@"error"];
    }
    NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    
    self.errorNotification = [[MXKAlert alloc] initWithTitle:title message:msg style:MXKAlertStyleAlert];
    self.errorNotification.cancelButtonIndex = [self.errorNotification addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert)
    {
        [AppDelegate theDelegate].errorNotification = nil;
    }];
    [self.errorNotification showInViewController:[self.masterTabBarController selectedViewController]];
    
    // Switch in offline mode in case of network reachability error
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorNotConnectedToInternet)
    {
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

- (void)enableInAppNotificationsForAccount:(MXKAccount*)account
{
    if (account.mxSession)
    {
        if (account.enableInAppNotifications)
        {
            // Build MXEvent -> NSString formatter
            MXKEventFormatter *eventFormatter = [[MXKEventFormatter alloc] initWithMatrixSession:account.mxSession];
            eventFormatter.isForSubtitle = YES;
            
            [account listenToNotifications:^(MXEvent *event, MXRoomState *roomState, MXPushRule *rule) {
                
                // Check conditions to display this notification
                if (![self.masterTabBarController.visibleRoomId isEqualToString:event.roomId]
                    && !self.masterTabBarController.presentedViewController)
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
                        [self.mxInAppNotification addActionWithTitle:NSLocalizedStringFromTable(@"view", @"MatrixConsole", nil)
                                                               style:MXKAlertActionStyleDefault
                                                             handler:^(MXKAlert *alert)
                         {
                             weakSelf.mxInAppNotification = nil;
                             // Show the room
                             [weakSelf.masterTabBarController showRoom:event.roomId withMatrixSession:account.mxSession];
                         }];
                        
                        [self.mxInAppNotification showInViewController:[self.masterTabBarController selectedViewController]];
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
            
            UIViewController *selectedViewController = [self.masterTabBarController selectedViewController];
            [selectedViewController presentViewController:currentCallViewController animated:YES completion:^{
                currentCallViewController.isPresented = YES;
            }];
            
            // Hide system status bar
            [UIApplication sharedApplication].statusBarHidden = YES;
        }
    }];
}

#pragma mark - Matrix Accounts handling

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
            [accountPicker addActionWithTitle:account.mxCredentials.userId style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert)
            {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                strongSelf->accountPicker = nil;
                
                if (onSelection)
                {
                    onSelection(account);
                }
            }];
        }
        
        accountPicker.cancelButtonIndex = [accountPicker addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert)
        {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->accountPicker = nil;
        }];
        
        accountPicker.sourceView = [self.masterTabBarController selectedViewController].view;
        [accountPicker showInViewController:[self.masterTabBarController selectedViewController]];
    }
}

#pragma mark - Matrix Rooms handling

- (void)startPrivateOneToOneRoomWithUserId:(NSString*)userId
{
    // Handle here potential multiple accounts
    [self selectMatrixAccount:^(MXKAccount *selectedAccount)
    {
        MXSession *mxSession = selectedAccount.mxSession;
        
        if (mxSession)
        {
            MXRoom* mxRoom = [mxSession privateOneToOneRoomWithUserId:userId];
            
            // if the room exists
            if (mxRoom)
            {
                // open it
                [self.masterTabBarController showRoom:mxRoom.state.roomId withMatrixSession:mxSession];
            } else
            {
                // create a new room
                [mxSession createRoom:nil
                           visibility:kMXRoomVisibilityPrivate
                            roomAlias:nil
                                topic:nil
                              success:^(MXRoom *room)
                {
                    // invite the other user only if it is defined and not onself
                    if (userId && ![mxSession.myUser.userId isEqualToString:userId])
                    {
                        // add the user
                        [room inviteUser:userId success:^{
                        } failure:^(NSError *error)
                        {
                            NSLog(@"[AppDelegate] %@ invitation failed (roomId: %@): %@", userId, room.state.roomId, error);
                            //Alert user
                            [self showErrorAsAlert:error];
                        }];
                    }
                    
                    // Open created room
                    [self.masterTabBarController showRoom:room.state.roomId withMatrixSession:mxSession];
                    
                } failure:^(NSError *error)
                {
                    NSLog(@"[AppDelegate] Create room failed: %@", error);
                    //Alert user
                    [self showErrorAsAlert:error];
                }];
            }
        }
    }];
}

#pragma mark - SplitViewController delegate

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController
{
    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[RoomViewController class]] && ([(RoomViewController *)[(UINavigationController *)secondaryViewController topViewController] roomDataSource] == nil))
    {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    } else
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

#pragma mark - UITabBarControllerDelegate delegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    BOOL res = YES;
    
    if (tabBarController.selectedIndex == TABBAR_SETTINGS_INDEX)
    {
        // Prompt user to save unsaved profile changes before switching to another tab
        UIViewController* selectedViewController = [tabBarController selectedViewController];
        if ([selectedViewController isKindOfClass:[UINavigationController class]])
        {
            UIViewController *topViewController = ((UINavigationController*)selectedViewController).topViewController;
            if ([topViewController isKindOfClass:[MXKAccountDetailsViewController class]])
            {
                res = [((MXKAccountDetailsViewController *)topViewController) shouldLeave:^()
                {
                    [topViewController.navigationController popViewControllerAnimated:NO];
                    
                    // This block is called when tab change is delayed to prompt user about his profile changes
                    NSUInteger nextSelectedViewController = [tabBarController.viewControllers indexOfObject:viewController];
                    tabBarController.selectedIndex = nextSelectedViewController;
                }];
            }
        }
    }
    return res;
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

#pragma mark - MXKContactDetailsViewControllerDelegate

- (void)contactDetailsViewController:(MXKContactDetailsViewController *)contactDetailsViewController startChatWithMatrixId:(NSString *)matrixId
{
    [self startPrivateOneToOneRoomWithUserId:matrixId];
}

#pragma mark - MXKRoomMemberDetailsViewControllerDelegate

- (void)roomMemberDetailsViewController:(MXKRoomMemberDetailsViewController *)roomMemberDetailsViewController startChatWithMemberId:(NSString *)matrixId
{
    [self startPrivateOneToOneRoomWithUserId:matrixId];
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
    NSString *btnTitle = NSLocalizedStringFromTable(@"return_to_call", @"MatrixConsole", nil);
    
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
    
    UIViewController *selectedViewController = [self.masterTabBarController selectedViewController];
    [selectedViewController presentViewController:currentCallViewController animated:YES completion:^{
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

@end
