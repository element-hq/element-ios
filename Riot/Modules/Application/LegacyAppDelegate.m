/*
 Copyright 2014 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
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

#import "LegacyAppDelegate.h"

#import <Intents/Intents.h>
#import <Contacts/Contacts.h>

#import "RecentsDataSource.h"
#import "RoomDataSource.h"

#import "EventFormatter.h"

#import "RoomViewController.h"

#import "DirectoryViewController.h"
#import "SettingsViewController.h"
#import "ContactDetailsViewController.h"

#import "BugReportViewController.h"
#import "RoomKeyRequestViewController.h"
#import "DecryptionFailureTracker.h"

#import "Tools.h"
#import "WidgetManager.h"

#import "AFNetworkReachabilityManager.h"

#import <AudioToolbox/AudioToolbox.h>

#include <MatrixSDK/MXUIKitBackgroundModeHandler.h>

#import "WebViewViewController.h"

// Calls
#import "CallViewController.h"

#import "MXSession+Riot.h"
#import "MXRoom+Riot.h"

#import "GeneratedInterface-Swift.h"
#import "PushNotificationService.h"

//#define MX_CALL_STACK_OPENWEBRTC
#ifdef MX_CALL_STACK_OPENWEBRTC
#import <MatrixOpenWebRTCWrapper/MatrixOpenWebRTCWrapper.h>
#endif

#ifdef MX_CALL_STACK_ENDPOINT
#import <MatrixEndpointWrapper/MatrixEndpointWrapper.h>
#endif


#if __has_include(<MatrixSDK/MXJingleCallStack.h>)
#define CALL_STACK_JINGLE
#endif
#ifdef CALL_STACK_JINGLE
#import <MatrixSDK/MXJingleCallStack.h>

#endif

#define CALL_STATUS_BAR_HEIGHT 44

NSString *const kAppDelegateDidTapStatusBarNotification = @"kAppDelegateDidTapStatusBarNotification";
NSString *const kAppDelegateNetworkStatusDidChangeNotification = @"kAppDelegateNetworkStatusDidChangeNotification";

NSString *const AppDelegateDidValidateEmailNotification = @"AppDelegateDidValidateEmailNotification";
NSString *const AppDelegateDidValidateEmailNotificationSIDKey = @"AppDelegateDidValidateEmailNotificationSIDKey";
NSString *const AppDelegateDidValidateEmailNotificationClientSecretKey = @"AppDelegateDidValidateEmailNotificationClientSecretKey";

NSString *const AppDelegateUniversalLinkDidChangeNotification = @"AppDelegateUniversalLinkDidChangeNotification";

@interface LegacyAppDelegate () <GDPRConsentViewControllerDelegate, KeyVerificationCoordinatorBridgePresenterDelegate, PushNotificationServiceDelegate, SetPinCoordinatorBridgePresenterDelegate, CallPresenterDelegate, SpaceDetailPresenterDelegate, SecureBackupSetupCoordinatorBridgePresenterDelegate>
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
     Incoming room key requests observers
     */
    id roomKeyRequestObserver;
    id roomKeyRequestCancellationObserver;

    /**
     If any the currently displayed sharing key dialog
     */
    RoomKeyRequestViewController *roomKeyRequestViewController;

    /**
     Incoming key verification requests observers
     */
    id incomingKeyVerificationObserver;

    /**
     If any the currently displayed key verification dialog
     */
    KeyVerificationCoordinatorBridgePresenter *keyVerificationCoordinatorBridgePresenter;
    
    /**
     Completion block for the requester of key verification
     */
    void (^keyVerificationCompletionBlock)(void);

    /**
     Currently displayed secure backup setup
     */
    SecureBackupSetupCoordinatorBridgePresenter *secureBackupSetupCoordinatorBridgePresenter;

    /**
     Account picker used in case of multiple account.
     */
    UIAlertController *accountPicker;
    
    /**
     Array of `MXSession` instances.
     */
    NSMutableArray *mxSessionArray;
    
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
     Prompt to warn the user about a new backup on the homeserver.
     */
    UIAlertController *wrongBackupVersionAlert;

    /**
     The launch animation container view
     */
    UIView *launchAnimationContainerView;
}

@property (strong, nonatomic) UIAlertController *logoutConfirmation;

@property (weak, nonatomic) UIAlertController *gdprConsentNotGivenAlertController;
@property (weak, nonatomic) UIViewController *gdprConsentController;

@property (weak, nonatomic) UIAlertController *incomingKeyVerificationRequestAlertController;

@property (nonatomic, strong) SlidingModalPresenter *slidingModalPresenter;
@property (nonatomic, strong) SetPinCoordinatorBridgePresenter *setPinCoordinatorBridgePresenter;
@property (nonatomic, strong) SpaceDetailPresenter *spaceDetailPresenter;

/**
 Used to manage on boarding steps, like create DM with riot bot
 */
@property (strong, nonatomic) OnBoardingManager *onBoardingManager;

@property (nonatomic, weak) id userDidSignInOnNewDeviceObserver;
@property (weak, nonatomic) UIAlertController *userNewSignInAlertController;

@property (nonatomic, weak) id userDidChangeCrossSigningKeysObserver;

/**
 Related push notification service instance. Will be created when launch finished.
 */
@property (nonatomic, strong) PushNotificationService *pushNotificationService;
@property (nonatomic, strong) PushNotificationStore *pushNotificationStore;
@property (nonatomic, strong) LocalAuthenticationService *localAuthenticationService;
@property (nonatomic, strong, readwrite) CallPresenter *callPresenter;
@property (nonatomic, strong, readwrite) id uisiAutoReporter;

@property (nonatomic, strong) MajorUpdateManager *majorUpdateManager;

@property (nonatomic, strong) SpaceFeatureUnavailablePresenter *spaceFeatureUnavailablePresenter;

@property (nonatomic, strong) AppInfo *appInfo;

/**
 Listen RecentsViewControllerDataReadyNotification for changes.
 */
@property (nonatomic, assign, getter=isRoomListDataReady) BOOL roomListDataReady;

/**
 An observer token for `RecentsViewControllerDataReadyNotification`s notifications.
 */
@property (nonatomic, nullable) id roomListDataReadyObserver;

/**
 An optional completion block that will be called when a `RecentsViewControllerDataReadyNotification`
 is observed during app launch.
 */
@property (nonatomic, copy, nullable) void (^roomListDataReadyCompletion)(void);

/**
 Flag to indicate whether a cache clear is being performed.
 */
@property (nonatomic, assign, getter=isClearingCache) BOOL clearingCache;

@end

@implementation LegacyAppDelegate

#pragma mark -

+ (void)initialize
{
    MXLogDebug(@"[AppDelegate] initialize");
        
    // Set static application settings
    [[AppConfiguration new] setupSettings];
    
    MXLogConfiguration *configuration = [[MXLogConfiguration alloc] init];
    configuration.logLevel = MXLogLevelVerbose;
    configuration.logFilesSizeLimit = 100 * 1024 * 1024; // 100MB
    configuration.maxLogFilesCount = 50;
    
    // Redirect NSLogs to files only if we are not debugging
    if (!isatty(STDERR_FILENO)) {
        configuration.redirectLogsToFiles = YES;
    }
    
    [MXLog configure:configuration];

    MXLogDebug(@"[AppDelegate] initialize: Done");
}

+ (instancetype)theDelegate
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}


#pragma mark - Push Notifications

- (void)registerForRemoteNotificationsWithCompletion:(nullable void (^)(NSError *))completion
{
    [self.pushNotificationService registerForRemoteNotificationsWithCompletion:completion];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [self.pushNotificationService didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    
    NSString * deviceTokenString = [[[[deviceToken description]
                                      stringByReplacingOccurrencesOfString: @"<" withString: @""]
                                     stringByReplacingOccurrencesOfString: @">" withString: @""]
                                    stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    MXLogDebug(@"The generated device token string is : %@",deviceTokenString);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [self.pushNotificationService didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [self.pushNotificationService didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}

#pragma mark -

- (NSString*)appVersion
{
    return self.appInfo.appVersion.bundleShortVersion;
}

- (NSString*)build
{
    return self.appInfo.buildInfo.readableBuildVersion;
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

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions
{
    // Create message sound
    NSURL *messageSoundURL = [[NSBundle mainBundle] URLForResource:@"message" withExtension:@"caf"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)messageSoundURL, &_messageSound);

    // Set up runtime language and fallback by considering the userDefaults object shared within the application group.
    NSUserDefaults *sharedUserDefaults = [MXKAppSettings standardAppSettings].sharedUserDefaults;
    NSString *language = [sharedUserDefaults objectForKey:@"appLanguage"];
    if (!language)
    {
        // Check whether a langage was only defined at the Riot application level.
        language = [[NSUserDefaults standardUserDefaults] objectForKey:@"appLanguage"];
        if (language)
        {
            // Move this setting into the shared userDefaults object to apply it to the extensions.
            [sharedUserDefaults setObject:language forKey:@"appLanguage"];

            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"appLanguage"];
        }
    }
    [NSBundle mxk_setLanguage:language];
    [NSBundle mxk_setFallbackLanguage:@"en"];
    
    if (BuildSettings.disableRightToLeftLayout)
    {
        [[UIView appearance] setSemanticContentAttribute:UISemanticContentAttributeForceLeftToRight];
    }
    
    // Set app info now as Mac (Designed for iPad) accesses it before didFinishLaunching is called
    self.appInfo = AppInfo.current;
    
    MXLogDebug(@"[AppDelegate] willFinishLaunchingWithOptions: Done");

    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSDate *startDate = [NSDate date];
    
#ifdef DEBUG
    // log the full launchOptions only in DEBUG
    MXLogDebug(@"[AppDelegate] didFinishLaunchingWithOptions: %@", launchOptions);
#else
    MXLogDebug(@"[AppDelegate] didFinishLaunchingWithOptions");
#endif

    MXLogDebug(@"[AppDelegate] didFinishLaunchingWithOptions: isProtectedDataAvailable: %@", @([application isProtectedDataAvailable]));

    _configuration = [AppConfiguration new];

    self.clearingCache = NO;
    // Log app information
    NSString *appDisplayName = self.appInfo.displayName;
    NSString* appVersion = self.appVersion;
    NSString* build = self.build;
    
    MXLogDebug(@"------------------------------");
    MXLogDebug(@"Application info:");
    MXLogDebug(@"%@ version: %@", appDisplayName, appVersion);
    MXLogDebug(@"MatrixSDK version: %@", MatrixSDKVersion);
    MXLogDebug(@"Build: %@\n", build);
    MXLogDebug(@"------------------------------\n");
    
    [self setupUserDefaults];

    // Set up theme
    ThemeService.shared.themeId = RiotSettings.shared.userInterfaceTheme;
    
    application.windows.firstObject.overrideUserInterfaceStyle = [ThemeService.shared isCurrentThemeDark] ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight;

    mxSessionArray = [NSMutableArray array];
    callEventsListeners = [NSMutableDictionary dictionary];

    // To simplify navigation into the app, we retrieve here the main navigation controller and the tab bar controller.
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    
    _masterNavigationController = splitViewController.viewControllers[0];
    _masterTabBarController = _masterNavigationController.viewControllers.firstObject;
    
    // Sanity check
    NSAssert(_masterTabBarController, @"Something wrong in Main.storyboard");
    
    _isAppForeground = NO;
    _handleSelfVerificationRequest = YES;
    
    // Configure our analytics. It will start if the option is enabled
    Analytics *analytics = Analytics.shared;
    [MXSDKOptions sharedInstance].analyticsDelegate = analytics;
    [DecryptionFailureTracker sharedInstance].delegate = analytics;
    
    MXBaseProfiler *profiler = [MXBaseProfiler new];
    profiler.analytics = analytics;
    [MXSDKOptions sharedInstance].profiler = profiler;
    
    [analytics startIfEnabled];

    self.localAuthenticationService = [[LocalAuthenticationService alloc] initWithPinCodePreferences:[PinCodePreferences shared]];
    
    self.callPresenter = [[CallPresenter alloc] init];
    self.callPresenter.delegate = self;

    self.pushNotificationStore = [PushNotificationStore new];
    self.pushNotificationService = [[PushNotificationService alloc] initWithPushNotificationStore:self.pushNotificationStore];
    self.pushNotificationService.delegate = self;
        
    self.spaceFeatureUnavailablePresenter = [SpaceFeatureUnavailablePresenter new];

    self.uisiAutoReporter = [[UISIAutoReporter alloc] init];

    // Add matrix observers, and initialize matrix sessions if the app is not launched in background.
    [self initMatrixSessions];
    
#ifdef CALL_STACK_JINGLE
    // Setup Jitsi
    NSURL *jitsiServerUrl = BuildSettings.jitsiServerUrl;
    if (jitsiServerUrl)
    {
        [JitsiService.shared configureDefaultConferenceOptionsWith:jitsiServerUrl];

        [JitsiService.shared application:application didFinishLaunchingWithOptions:launchOptions];
    }

#endif
    
    self.majorUpdateManager = [MajorUpdateManager new];

    MXLogDebug(@"[AppDelegate] didFinishLaunchingWithOptions: Done in %.0fms", [[NSDate date] timeIntervalSinceDate:startDate] * 1000);

    dispatch_async(dispatch_get_main_queue(), ^{
        [self configurePinCodeScreenFor:application createIfRequired:YES];
    });
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    MXLogDebug(@"[AppDelegate] applicationWillResignActive");
    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    [self.pushNotificationService applicationWillResignActive];
    
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

    if (wrongBackupVersionAlert)
    {
        [wrongBackupVersionAlert dismissViewControllerAnimated:NO completion:nil];
        wrongBackupVersionAlert = nil;
    }
    
    if ([self.localAuthenticationService isProtectionSet] && ![BiometricsAuthenticationPresenter isPresenting])
    {
        if (self.setPinCoordinatorBridgePresenter)
        {
            //  it's already on screen, convert the viewMode
            self.setPinCoordinatorBridgePresenter.viewMode = SetPinCoordinatorViewModeInactive;
            return;
        }
        self.setPinCoordinatorBridgePresenter = [[SetPinCoordinatorBridgePresenter alloc] initWithSession:mxSessionArray.firstObject viewMode:SetPinCoordinatorViewModeInactive];
        self.setPinCoordinatorBridgePresenter.delegate = self;
        [self.setPinCoordinatorBridgePresenter presentWithMainAppWindow:self.window];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    MXLogDebug(@"[AppDelegate] applicationDidEnterBackground");
    
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
    
    // Remove expired URL previews from the cache
    [URLPreviewService.shared removeExpiredCacheData];
    
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
    
    [self.pushNotificationService applicationDidEnterBackground];
    
    // Pause profiling
    [MXSDKOptions.sharedInstance.profiler pause];
    
    // Analytics: Force to send the pending actions
    [[DecryptionFailureTracker sharedInstance] dispatch];
    [Analytics.shared forceUpload];
    
    // Pause Voice Broadcast recording if needed
    [VoiceBroadcastRecorderProvider.shared pauseRecording];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    MXLogDebug(@"[AppDelegate] applicationWillEnterForeground");
    
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

    [MXSDKOptions.sharedInstance.profiler resume];
    
    _isAppForeground = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    MXLogDebug(@"[AppDelegate] applicationDidBecomeActive");
    
    [self.pushNotificationService applicationDidBecomeActive];
    
    [self configurePinCodeScreenFor:application createIfRequired:NO];
    
    [self checkCrossSigningForSession:self.mxSessions.firstObject];
}

- (void)configurePinCodeScreenFor:(UIApplication *)application
                 createIfRequired:(BOOL)createIfRequired
{
    if ([self.localAuthenticationService shouldShowPinCode])
    {
        if (self.setPinCoordinatorBridgePresenter)
        {
            //  it's already on screen, convert the viewMode
            self.setPinCoordinatorBridgePresenter.viewMode = SetPinCoordinatorViewModeUnlock;
            return;
        }
        if (createIfRequired)
        {
            self.setPinCoordinatorBridgePresenter = [[SetPinCoordinatorBridgePresenter alloc] initWithSession:mxSessionArray.firstObject viewMode:SetPinCoordinatorViewModeUnlock];
            self.setPinCoordinatorBridgePresenter.delegate = self;
            [self.setPinCoordinatorBridgePresenter presentWithMainAppWindow:self.window];
        }
    }
    else
    {
        [self.setPinCoordinatorBridgePresenter dismissWithMainAppWindow:self.window];
        self.setPinCoordinatorBridgePresenter = nil;
        [self afterAppUnlockedByPin:application];
    }
}

- (void)afterAppUnlockedByPin:(UIApplication *)application
{
    MXLogDebug(@"[AppDelegate] afterAppUnlockedByPin");
    
    // Check if there is crash log to send
    if (RiotSettings.shared.enableAnalytics)
    {
        #if DEBUG
        // Don't show alerts for crashes during development.
        #else
        [self checkExceptionToReport];
        #endif
    }
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    // Check if an initial sync failure occured while the app was in background
    MXSession *mainSession = self.mxSessions.firstObject;
    if (mainSession.state == MXSessionStateInitialSyncFailed)
    {
        // Inform the end user why the app appears blank
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                             code:NSURLErrorCannotConnectToHost
                                         userInfo:@{NSLocalizedDescriptionKey : [VectorL10n homeserverConnectionLost]}];

        [self showErrorAsAlert:error];
    }
    
    // Register to GDPR consent not given notification
    [self registerUserConsentNotGivenNotification];
    
    // Start monitoring reachability
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        // Check whether monitoring is ready
        if (status != AFNetworkReachabilityStatusUnknown)
        {
            if (status == AFNetworkReachabilityStatusNotReachable)
            {
                // Prompt user
                [[AppDelegate theDelegate] showErrorAsAlert:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:@{NSLocalizedDescriptionKey : [VectorL10n networkOfflinePrompt]}]];
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

    // Observe wrong backup version
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBackupStateDidChangeNotification:) name:kMXKeyBackupDidStateChangeNotification object:nil];

    // Resume all existing matrix sessions
    NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    for (MXKAccount *account in mxAccounts)
    {
        [account resume];
    }
    
    _isAppForeground = YES;
    
    // Riot has its own dark theme. Prevent iOS from applying its one
    [application keyWindow].accessibilityIgnoresInvertColors = YES;
    
    [self handleAppState];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    MXLogDebug(@"[AppDelegate] applicationWillTerminate");
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    MXLogDebug(@"[AppDelegate] applicationDidReceiveMemoryWarning");
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler
{
    BOOL continueUserActivity = NO;
    
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb])
    {
        continueUserActivity = [self handleUniversalLink:userActivity];
    }
    else if ([userActivity.activityType isEqualToString:INStartAudioCallIntentIdentifier] ||
             [userActivity.activityType isEqualToString:INStartVideoCallIntentIdentifier])
    {
        INInteraction *interaction = userActivity.interaction;
        
        // roomID provided by Siri intent
        NSString *roomID = userActivity.userInfo[@"roomID"];
        
        // We've launched from calls history list
        if (!roomID)
        {
            INPerson *person;
            
            if ([interaction.intent isKindOfClass:INStartAudioCallIntent.class])
            {
                person = [[(INStartAudioCallIntent *)(interaction.intent) contacts] firstObject];
            }
            else if ([interaction.intent isKindOfClass:INStartVideoCallIntent.class])
            {
                person = [[(INStartVideoCallIntent *)(interaction.intent) contacts] firstObject];
            }
            
            roomID = person.personHandle.value;
        }
        
        BOOL isVideoCall = [userActivity.activityType isEqualToString:INStartVideoCallIntentIdentifier];
        
        UIApplication *application = UIApplication.sharedApplication;
        
        id<MXBackgroundModeHandler> handler = [MXSDKOptions sharedInstance].backgroundModeHandler;
        id<MXBackgroundTask> backgroundTask;
        
        // Start background task since we need time for MXSession preparasion because our app can be launched in the background
        if (application.applicationState == UIApplicationStateBackground)
        {
            backgroundTask = [handler startBackgroundTaskWithName:@"[AppDelegate] application:continueUserActivity:restorationHandler: Audio or video call" expirationHandler:nil];
        }

        MXSession *session = mxSessionArray.firstObject;
        [session.callManager placeCallInRoom:roomID
                                   withVideo:isVideoCall
                                     success:^(MXCall *call) {
                                         if (application.applicationState == UIApplicationStateBackground)
                                         {
                                             __weak NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
                                             __block id token =
                                             [center addObserverForName:kMXCallStateDidChange
                                                                 object:call
                                                                  queue:nil
                                                             usingBlock:^(NSNotification * _Nonnull note) {
                                                                 if (call.state == MXCallStateEnded)
                                                                 {
                                                                     [backgroundTask stop];
                                                                     [center removeObserver:token];
                                                                 }
                                                             }];
                                         }
                                     }
                                     failure:^(NSError *error) {
                                         if (backgroundTask)
                                         {
                                             [backgroundTask stop];
                                         }
                                     }];
        
        continueUserActivity = YES;
    }
    
    return continueUserActivity;
}

#pragma mark - Application layout handling

- (void)restoreInitialDisplay:(void (^)(void))completion
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
                self->isErrorNotificationSuspended = NO;
                
                if (self->noCallSupportAlert)
                {
                    MXLogDebug(@"[AppDelegate] restoreInitialDisplay: keep visible noCall support alert");
                    [self showNotificationAlert:self->noCallSupportAlert];
                }
                else if (self->cryptoDataCorruptedAlert)
                {
                    MXLogDebug(@"[AppDelegate] restoreInitialDisplay: keep visible log in again");
                    [self showNotificationAlert:self->cryptoDataCorruptedAlert];
                }
                else if (self->wrongBackupVersionAlert)
                {
                    MXLogDebug(@"[AppDelegate] restoreInitialDisplay: keep visible wrongBackupVersionAlert");
                    [self showNotificationAlert:self->wrongBackupVersionAlert];

                }
                // Check whether an error notification is pending
                else if (self->_errorNotification)
                {
                    [self showNotificationAlert:self->_errorNotification];
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
            self->isErrorNotificationSuspended = NO;
            if (self->_errorNotification)
            {
                [self showNotificationAlert:self->_errorNotification];
            }
        }];
    }
}

- (void)restoreEmptyDetailsViewController
{
    [self.delegate legacyAppDelegateRestoreEmptyDetailsViewController:self];
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
    
    // Ignore GDPR Consent not given error. Already caught by kMXHTTPClientUserConsentNotGivenErrorNotification observation
    if ([MXError isMXError:error])
    {
        MXError *mxError = [[MXError alloc] initWithNSError:error];
        if ([mxError.errcode isEqualToString:kMXErrCodeStringConsentNotGiven])
        {
            return nil;
        }
    }

    NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
    NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    NSString *localizedDescription = error.localizedDescription;
    if (!title)
    {
        if (msg)
        {
            title = msg;
            msg = nil;
        }
        else if (localizedDescription.length > 0)
        {
            title = localizedDescription;
        }
        else
        {
            title = [VectorL10n error];
        }
    }
    
    // Switch in offline mode in case of network reachability error
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorNotConnectedToInternet)
    {
        self.isOffline = YES;
    }

    return [self showAlertWithTitle:title message:msg];
}

- (UIAlertController*)showAlertWithTitle:(NSString*)title message:(NSString*)message
{
    [_errorNotification dismissViewControllerAnimated:NO completion:nil];

    _errorNotification = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [_errorNotification addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
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

    return self.errorNotification;
}

- (void)showNotificationAlert:(UIAlertController*)alert
{
    [alert popoverPresentationController].sourceView = self.presentedViewController.view;
    [alert popoverPresentationController].sourceRect = self.presentedViewController.view.bounds;
    [self.presentedViewController presentViewController:alert animated:YES completion:nil];
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
                                                                       message:[VectorL10n e2eNeedLogInAgain]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        __weak typeof(self) weakSelf = self;
        
        [cryptoDataCorruptedAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n later]
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       
                                                                       if (weakSelf)
                                                                       {
                                                                           typeof(self) self = weakSelf;
                                                                           self->cryptoDataCorruptedAlert = nil;
                                                                       }
                                                                       
                                                                   }]];
        
        [cryptoDataCorruptedAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n settingsSignOut]
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

- (void)keyBackupStateDidChangeNotification:(NSNotification *)notification
{
    MXKeyBackup *keyBackup = notification.object;

    if (keyBackup.state == MXKeyBackupStateWrongBackUpVersion)
    {
        if (wrongBackupVersionAlert)
        {
            [wrongBackupVersionAlert dismissViewControllerAnimated:NO completion:nil];
        }

        wrongBackupVersionAlert = [UIAlertController alertControllerWithTitle:[VectorL10n e2eKeyBackupWrongVersionTitle]
                                                                      message:[VectorL10n e2eKeyBackupWrongVersion]
                                                               preferredStyle:UIAlertControllerStyleAlert];

        MXWeakify(self);
        [wrongBackupVersionAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n e2eKeyBackupWrongVersionButtonSettings]
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action)
                                             {
                                                 MXStrongifyAndReturnIfNil(self);
                                                 self->wrongBackupVersionAlert = nil;

                                                 // TODO: Open settings
                                             }]];

        [wrongBackupVersionAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n e2eKeyBackupWrongVersionButtonWasme]
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action)
                                             {
                                                 MXStrongifyAndReturnIfNil(self);
                                                 self->wrongBackupVersionAlert = nil;
                                             }]];

        [self showNotificationAlert:wrongBackupVersionAlert];
    }
}

#pragma mark

- (void)popToHomeViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    [self.delegate legacyAppDelegate:self wantsToPopToHomeViewControllerAnimated:animated completion:completion];
}

#pragma mark - Crash handling

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
        
        MXLogDebug(@"[AppDelegate] Promt user to report crash:\n%@", description);

        // Ask the user to send a crash report
        [[RageShakeManager sharedManager] promptCrashReportInViewController:self.window.rootViewController];
    }
}

#pragma mark - PushNotificationServiceDelegate

- (void)pushNotificationService:(PushNotificationService *)pushNotificationService
     shouldNavigateToRoomWithId:(NSString *)roomId
                       threadId:(NSString *)threadId
                         sender:(NSString *)userId
{
    void(^sessionReadyBlock)(MXSession*) = ^(MXSession *session){
        if (roomId)
        {
            MXRoom *room = [session roomWithRoomId:roomId];
            if (room.summary.membership != MXMembershipJoin)
            {
                Analytics.shared.joinedRoomTrigger = AnalyticsJoinedRoomTriggerNotification;
            }
            else
            {
                Analytics.shared.viewRoomTrigger = AnalyticsViewRoomTriggerNotification;
            }
        }

        self.lastNavigatedRoomIdFromPush = roomId;

        if (threadId)
        {
            if(![[MXKRoomDataSourceManager sharedManagerForMatrixSession:session] hasRoomDataSourceForRoom:roomId])
            {
                //  the room having this thread probably was not opened before, paginate room messages to build threads
                MXRoom *room = [session roomWithRoomId:roomId];
                [room liveTimeline:^(id<MXEventTimeline> liveTimeline) {
                    [liveTimeline resetPagination];
                    [liveTimeline paginate:NSUIntegerMax direction:MXTimelineDirectionBackwards onlyFromStore:YES complete:^{
                        [liveTimeline resetPagination];
                        [self navigateToRoomById:roomId threadId:threadId sender:userId];
                    } failure:^(NSError * _Nonnull error) {
                        [self navigateToRoomById:roomId threadId:threadId sender:userId];
                    }];
                }];
            }
            else
            {
                //  the room has been opened before, we should be ok to continue
                [self navigateToRoomById:roomId threadId:threadId sender:userId];
            }
        }
        else
        {
            [self navigateToRoomById:roomId threadId:threadId sender:userId];
        }
    };

    MXSession *mxSession = self.mxSessions.firstObject;
    if (mxSession.state >= MXSessionStateSyncInProgress)
    {
        sessionReadyBlock(mxSession);
    }
    else
    {
        //  wait for session state to be sync in progress
        __block id sessionStateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionStateDidChangeNotification object:mxSession queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            if (mxSession.state >= MXSessionStateSyncInProgress)
            {
                [[NSNotificationCenter defaultCenter] removeObserver:sessionStateObserver];
                sessionReadyBlock(mxSession);
            }
        }];
    }
}

#pragma mark - Badge Count

- (void)refreshApplicationIconBadgeNumber
{
    // Consider the total number of missed discussions including the invites.
    NSUInteger count = [self.masterTabBarController missedDiscussionsCount];

    MXLogDebug(@"[AppDelegate] refreshApplicationIconBadgeNumber: %tu", count);

    [UIApplication sharedApplication].applicationIconBadgeNumber = count;
}

#pragma mark - Universal link

- (BOOL)handleUniversalLink:(NSUserActivity*)userActivity
{
    NSURL *webURL = userActivity.webpageURL;
    MXLogDebug(@"[AppDelegate] handleUniversalLink: %@", webURL.absoluteString);
    
    // iOS Patch: fix vector.im urls before using it
    webURL = [Tools fixURLWithSeveralHashKeys:webURL];

    // Extract required parameters from the link
    UniversalLink *newLink = [[UniversalLink alloc] initWithUrl:webURL];
    NSDictionary<NSString*, NSString*> *queryParams = newLink.queryParams;

    if (![_lastHandledUniversalLink isEqual:newLink])
    {
        _lastHandledUniversalLink = newLink;
        //  notify this change
        [[NSNotificationCenter defaultCenter] postNotificationName:AppDelegateUniversalLinkDidChangeNotification object:nil];
    }

    if ([AuthenticationService.shared handleServerProvisioningLink:newLink])
    {
        return YES;
    }
    
    NSString *validateEmailSubmitTokenPath = @"validate/email/submitToken";
    
    NSString *validateEmailSubmitTokenAPIPathV1 = [NSString stringWithFormat:@"/%@/%@", kMXIdentityAPIPrefixPathV1, validateEmailSubmitTokenPath];
    NSString *validateEmailSubmitTokenAPIPathV2 = [NSString stringWithFormat:@"/%@/%@", kMXIdentityAPIPrefixPathV2, validateEmailSubmitTokenPath];
    
    // Manage email validation links from homeserver for registration (/registration/email/submit_token)
    // and email addition (/add_threepid/email/submit_token)
    // They look like https://matrix.org/_matrix/client/unstable/registration/email/submit_token?token=vtQjQIZfwdoREDACTEDozrmKYSWlCXsJ&client_secret=53e679ea-oRED-ACTED-92b8-3012c49c6cfa&sid=qlBCREDACTEDEtgxD
    if ([webURL.path hasSuffix:@"/email/submit_token"])
    {
        MXLogDebug(@"[AppDelegate] handleUniversalLink: Validate link");
        
        // We just need to ping the link.
        // The app should be in the registration flow at the "waiting for email validation" polling state. The server
        // will indicate the email is validated through this polling API. Then, the app will go to the next flow step.
        NSURLSessionConfiguration *conf = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:conf];
        
        NSURLSessionDataTask * task = [urlSession dataTaskWithURL:webURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            MXLogDebug(@"[AppDelegate] handleUniversalLink: Link validation response: %@\nData: %@", response,
                  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            
            if (error)
            {
                MXLogDebug(@"[AppDelegate] handleUniversalLink: Link validation error: %@", error);
                [self showErrorAsAlert:error];
            }
        }];
        
        [task resume];
        
        return YES;
    }
    
    // Manage email validation link from identity server v1 or v2
    else if ([webURL.path isEqualToString:validateEmailSubmitTokenAPIPathV1]
             || [webURL.path isEqualToString:validateEmailSubmitTokenAPIPathV2])
    {
        // Validate the email on the passed identity server
        NSString *identityServer = [NSString stringWithFormat:@"%@://%@", webURL.scheme, webURL.host];
        
        MXSession *mainSession = self.mxSessions.firstObject;
        MXRestClient *homeserverRestClient;
        
        if (mainSession.matrixRestClient)
        {
            homeserverRestClient = mainSession.matrixRestClient;
        }
        else
        {
            homeserverRestClient = [[MXRestClient alloc] initWithHomeServer:identityServer andOnUnrecognizedCertificateBlock:nil];
        }
        
        MXIdentityService *identityService = [[MXIdentityService alloc] initWithIdentityServer:identityServer accessToken:nil andHomeserverRestClient:homeserverRestClient];

        NSString *clientSecret = queryParams[@"client_secret"];
        NSString *sid = queryParams[@"sid"];
        
        [identityService submit3PIDValidationToken:queryParams[@"token"] medium:kMX3PIDMediumEmail clientSecret:clientSecret sid:sid success:^{
            
            MXLogDebug(@"[AppDelegate] handleUniversalLink. Email successfully validated.");
            
            if (queryParams[@"nextLink"])
            {
                // Continue the registration with the passed nextLink
                MXLogDebug(@"[AppDelegate] handleUniversalLink. Complete registration with nextLink");
                NSURL *nextLink = [NSURL URLWithString:queryParams[@"nextLink"]];
                [self handleUniversalLinkURL:nextLink];
            }
            else
            {
                // No nextLink in Vector world means validation for binding a new email
                
                // Post a notification about email validation to make a chance to SettingsDiscoveryThreePidDetailsViewModel to make it discoverable or not by the identity server.
                if (clientSecret && sid)
                {
                    NSDictionary *userInfo = @{ AppDelegateDidValidateEmailNotificationClientSecretKey : clientSecret,
                                                AppDelegateDidValidateEmailNotificationSIDKey : sid };
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:AppDelegateDidValidateEmailNotification object:nil userInfo:userInfo];
                }
            }
            
        } failure:^(NSError *error) {
            
            MXLogDebug(@"[AppDelegate] handleUniversalLink. Error: submitToken failed");
            [self showErrorAsAlert:error];
            
        }];
        
        return YES;
    }
    
    return [self handleUniversalLinkFragment:webURL.fragment fromLink:newLink];
}

- (BOOL)handleUniversalLinkFragment:(NSString*)fragment fromLink:(UniversalLink*)universalLink
{
    if (!fragment || !universalLink)
    {
        MXLogDebug(@"[AppDelegate] Cannot handle universal link with missing data: %@ %@", fragment, universalLink.url);
        return NO;
    }
    ScreenPresentationParameters *presentationParameters = [[ScreenPresentationParameters alloc] initWithRestoreInitialDisplay:YES stackAboveVisibleViews:NO];
    
    UniversalLinkParameters *parameters = [[UniversalLinkParameters alloc] initWithFragment:fragment universalLink:universalLink presentationParameters:presentationParameters];
    
    return [self handleUniversalLinkWithParameters:parameters];
}

- (BOOL)handleUniversalLinkWithParameters:(UniversalLinkParameters*)universalLinkParameters
{
    NSString *fragment = universalLinkParameters.fragment;
    UniversalLink *universalLink = universalLinkParameters.universalLink;
    ScreenPresentationParameters *presentationParameters = universalLinkParameters.presentationParameters;
    BOOL restoreInitialDisplay = presentationParameters.restoreInitialDisplay;
    
    BOOL continueUserActivity = NO;
    MXKAccountManager *accountManager = [MXKAccountManager sharedManager];
    
    // Make sure we have plain utf8 character for separators
    fragment = [fragment stringByRemovingPercentEncoding];
    MXLogDebug(@"[AppDelegate] Universal link: handleUniversalLinkFragment: %@", fragment);
    
    // The app manages only one universal link at a time
    // Discard any pending one
    [self resetPendingUniversalLink];
    
    // Extract params
    NSArray<NSString*> *pathParams = universalLink.pathParams;
    NSDictionary<NSString*, NSString*> *queryParams = universalLink.queryParams;
    
    // Sanity check
    if (!pathParams.count)
    {
        MXLogFailure(@"[AppDelegate] Universal link: Error: No path parameters");
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
                MXRoom *room;
                
                // Translate the alias into the room id
                if ([roomIdOrAlias hasPrefix:@"#"])
                {
                    room = [account.mxSession roomWithAlias:roomIdOrAlias];
                    if (room)
                    {
                        roomId = room.roomId;
                    }
                }
                else
                {
                    room = [account.mxSession roomWithRoomId:roomId];
                }
                
                if (room.summary.roomType == MXRoomTypeSpace)
                {
                    SpaceNavigationParameters *spaceNavigationParameters = [[SpaceNavigationParameters alloc] initWithRoomId:room.roomId mxSession:account.mxSession presentationParameters:presentationParameters];
                    
                    [self showSpaceWithParameters:spaceNavigationParameters];
                }
                else
                {
                    // Open the room page
                    if (eventId)
                    {
                        __block MXEvent *event = [account.mxSession.store eventWithEventId:eventId inRoom:roomId];
                        dispatch_group_t eventDispatchGroup = dispatch_group_create();
                        
                        if (event == nil)
                        {
                            dispatch_group_enter(eventDispatchGroup);
                            //  event doesn't exist in the store
                            [account.mxSession eventWithEventId:eventId
                                                         inRoom:roomId
                                                        success:^(MXEvent *eventFromServer) {
                                event = eventFromServer;
                                dispatch_group_leave(eventDispatchGroup);
                            } failure:^(NSError *error) {
                                MXLogErrorDetails(@"[LegacyAppDelegate] handleUniversalLinkWithParameters: event fetch failed", @{
                                    @"error": error ?: @"unknown"
                                });
                                dispatch_group_leave(eventDispatchGroup);
                            }];
                        }
                        
                        dispatch_group_notify(eventDispatchGroup, dispatch_get_main_queue(), ^{
                            if (event == nil)
                            {
                                return;
                            }
                            
                            ThreadParameters *threadParameters = nil;
                            if (RiotSettings.shared.enableThreads)
                            {
                                if (event.threadId)
                                {
                                    threadParameters = [[ThreadParameters alloc] initWithThreadId:event.threadId
                                                                                  stackRoomScreen:NO];
                                }
                                else if ([account.mxSession.threadingService threadWithId:eventId])
                                {
                                    threadParameters = [[ThreadParameters alloc] initWithThreadId:eventId
                                                                                  stackRoomScreen:NO];
                                }
                            }
                            
                            RoomNavigationParameters *parameters = [[RoomNavigationParameters alloc] initWithRoomId:roomId
                                                                                                            eventId:eventId
                                                                                                          mxSession:account.mxSession
                                                                                                   threadParameters:threadParameters
                                                                                             presentationParameters:presentationParameters];
                            [self showRoomWithParameters:parameters];
                        });
                    }
                    else
                    {
                        //  open the regular room timeline
                        RoomNavigationParameters *parameters = [[RoomNavigationParameters alloc] initWithRoomId:roomId
                                                                                                        eventId:eventId
                                                                                                      mxSession:account.mxSession
                                                                                               threadParameters:nil
                                                                                         presentationParameters:presentationParameters];
                        
                        [self showRoomWithParameters:parameters];
                    }
                }
                
                continueUserActivity = YES;
            }
            else
            {
                void(^findRoom)(void) = ^{
                    if ([self->_masterTabBarController.selectedViewController conformsToProtocol:@protocol(MXKViewControllerActivityHandling)])
                    {
                        UIViewController<MXKViewControllerActivityHandling> *homeViewController = (UIViewController<MXKViewControllerActivityHandling>*)self->_masterTabBarController.selectedViewController;
                        
                        [homeViewController startActivityIndicator];
                        
                        if ([roomIdOrAlias hasPrefix:@"#"])
                        {
                            // The alias may be not part of user's rooms states
                            // Ask the HS to resolve the room alias into a room id and then retry
                            self->universalLinkFragmentPending = fragment;
                            MXKAccount* account = accountManager.activeAccounts.firstObject;
                            [account.mxSession.matrixRestClient resolveRoomAlias:roomIdOrAlias success:^(MXRoomAliasResolution *resolution) {
                                
                                // Note: the activity indicator will not disappear if the session is not ready
                                [homeViewController stopActivityIndicator];
                                
                                // Check that 'fragment' has not been cancelled
                                if ([self->universalLinkFragmentPending isEqualToString:fragment])
                                {
                                    NSString *newFragment = resolution.deeplinkFragment;
                                    if (newFragment && ![newFragment isEqualToString:fragment])
                                    {
                                        self->universalLinkFragmentPendingRoomAlias = @{resolution.roomId: roomIdOrAlias};
                                        
                                        // Create a new link with the updated fragment, otherwise we loop back round resolving the room ID infinitely.
                                        UniversalLink *newLink = [[UniversalLink alloc] initWithUrl:universalLink.url updatedFragment:newFragment];
                                        UniversalLinkParameters *newParameters = [[UniversalLinkParameters alloc] initWithFragment:newFragment
                                                                                                                     universalLink:newLink
                                                                                                            presentationParameters:presentationParameters];
                                        [self handleUniversalLinkWithParameters:newParameters];
                                    }
                                    else
                                    {
                                        // Do not continue. Else we will loop forever
                                        MXLogDebug(@"[AppDelegate] Universal link: Error: Cannot resolve alias in %@ to the room id %@", fragment, resolution.roomId);
                                    }
                                }
                                
                            } failure:^(NSError *error) {
                                MXLogDebug(@"[AppDelegate] Universal link: Error: The homeserver failed to resolve the room alias (%@)", roomIdOrAlias);

                                [homeViewController stopActivityIndicator];

                                NSString *errorMessage = [VectorL10n roomDoesNotExist:roomIdOrAlias];

                                [self showAlertWithTitle:nil message:errorMessage];
                            }];
                        }
                        else if ([roomIdOrAlias hasPrefix:@"!"] && ((MXKAccount*)accountManager.activeAccounts.firstObject).mxSession.state != MXSessionStateRunning)
                        {
                            // The user does not know the room id but this may be because their session is not yet sync'ed
                            // So, wait for the completion of the sync and then retry
                            // FIXME: Manange all user's accounts not only the first one
                            MXKAccount* account = accountManager.activeAccounts.firstObject;
                            
                            MXLogDebug(@"[AppDelegate] Universal link: Need to wait for the session to be sync'ed and running");
                            self->universalLinkFragmentPending = fragment;
                            
                            self->universalLinkWaitingObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notif) {
                                
                                // Check that 'fragment' has not been cancelled
                                if ([self->universalLinkFragmentPending isEqualToString:fragment])
                                {
                                    // Check whether the concerned session is the associated one
                                    if (notif.object == account.mxSession && account.mxSession.state == MXSessionStateRunning)
                                    {
                                        MXLogDebug(@"[AppDelegate] Universal link: The session is running. Retry the link");
                                        [self handleUniversalLinkWithParameters:universalLinkParameters];
                                    }
                                }
                            }];
                        }
                        else
                        {
                            MXLogDebug(@"[AppDelegate] Universal link: The room (%@) is not known by any account (email invitation: %@). Display its preview to try to join it", roomIdOrAlias, queryParams ? @"YES" : @"NO");
                            
                            // FIXME: In case of multi-account, ask the user which one to use
                            MXKAccount* account = accountManager.activeAccounts.firstObject;
                            
                            RoomPreviewData *roomPreviewData = [[RoomPreviewData alloc] initWithRoomId:roomIdOrAlias
                                                                                            andSession:account.mxSession];
                            if (queryParams)
                            {
                                roomPreviewData.viaServers = queryParams[@"via"];
                            }
                            
                            RoomPreviewNavigationParameters *roomPreviewNavigationParameters = [[RoomPreviewNavigationParameters alloc] initWithPreviewData:roomPreviewData presentationParameters:presentationParameters];
                            
                            [account.mxSession.matrixRestClient roomSummaryWith:roomIdOrAlias via:roomPreviewData.viaServers success:^(MXPublicRoom *room) {
                                if ([room.roomTypeString isEqualToString:MXRoomTypeStringSpace])
                                {
                                    [homeViewController stopActivityIndicator];
                                    
                                    SpacePreviewNavigationParameters *spacePreviewNavigationParameters = [[SpacePreviewNavigationParameters alloc] initWithPublicRoom:room mxSession:account.mxSession presentationParameters:presentationParameters];
                                    
                                    [self showSpacePreviewWithParameters:spacePreviewNavigationParameters];  
                                }
                                else
                                {
                                    [self peekInRoomWithNavigationParameters:roomPreviewNavigationParameters pathParams:pathParams];
                                }
                            } failure:^(NSError *error) {
                                [self peekInRoomWithNavigationParameters:roomPreviewNavigationParameters pathParams:pathParams];
                            }];
                        }
                        
                    }
                };
                
                
                // We will display something but we need to do some requests before.
                // So, come back to the home VC and show its loading wheel while processing
                
                if (restoreInitialDisplay)
                {
                    [self restoreInitialDisplay:^{
                        findRoom();
                    }];
                }
                else
                {
                    findRoom();
                }
                                
                
                // Let's say we are handling the case
                continueUserActivity = YES;
            }
        }
        else
        {
            // There is no account. The app will display the AuthenticationVC.
            // Wait for a successful login
            MXLogDebug(@"[AppDelegate] Universal link: The user is not logged in. Wait for a successful login");
            universalLinkFragmentPending = fragment;
            
            // Register an observer in order to handle new account
            universalLinkWaitingObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidAddAccountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
                
                // Check that 'fragment' has not been cancelled
                if ([self->universalLinkFragmentPending isEqualToString:fragment])
                {
                    MXLogDebug(@"[AppDelegate] Universal link:  The user is now logged in. Retry the link");
                    [self handleUniversalLinkWithParameters:universalLinkParameters];
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
        [self showContact:contact presentationParameters:presentationParameters];

        continueUserActivity = YES;
    }
    else
    {
        // Unknown command: Do nothing except coming back to the main screen
        MXLogDebug(@"[AppDelegate] Universal link: TODO: Do not know what to do with the link arguments: %@", pathParams);
        
        if (restoreInitialDisplay)
        {
            [self popToHomeViewControllerAnimated:NO completion:nil];
        }
    }
    
    return continueUserActivity;
}

- (BOOL)handleUniversalLinkURL:(NSURL*)universalLinkURL
{
    // iOS Patch: fix vector.im urls before using it
    NSURL *fixedURL = [Tools fixURLWithSeveralHashKeys:universalLinkURL];
    UniversalLink *link = [[UniversalLink alloc] initWithUrl:universalLinkURL];
    
    return [self handleUniversalLinkFragment:fixedURL.fragment fromLink:link];
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

- (void)peekInRoomWithNavigationParameters:(RoomPreviewNavigationParameters*)presentationParameters pathParams:(NSArray<NSString*> *)pathParams
{
    RoomPreviewData *roomPreviewData = presentationParameters.previewData;
    NSString *roomIdOrAlias = presentationParameters.roomId;
    
    // Is it a link to an event of a room?
    // If yes, the event will be displayed once the room is joined
    roomPreviewData.eventId = (pathParams.count >= 3) ? pathParams[2] : nil;
    
    MXWeakify(self);
    // Try to get more information about the room before opening its preview
    [roomPreviewData peekInRoom:^(BOOL succeeded) {
        MXStrongifyAndReturnIfNil(self);
        if ([self.masterTabBarController.selectedViewController conformsToProtocol:@protocol(MXKViewControllerActivityHandling)])
        {
            UIViewController<MXKViewControllerActivityHandling> *homeViewController = (UIViewController<MXKViewControllerActivityHandling>*)self.masterTabBarController.selectedViewController;

            // Note: the activity indicator will not disappear if the session is not ready
            [homeViewController stopActivityIndicator];
        }
        
        // If no data is available for this room, we name it with the known room alias (if any).
        if (!succeeded && self->universalLinkFragmentPendingRoomAlias[roomIdOrAlias])
        {
            roomPreviewData.roomName = self->universalLinkFragmentPendingRoomAlias[roomIdOrAlias];
        }
        self->universalLinkFragmentPendingRoomAlias = nil;
        
        [self showRoomPreviewWithParameters:presentationParameters];
    }];
}

- (void)displayLogoutConfirmationForLink:(UniversalLink *)link
                              completion:(void (^)(BOOL loggedOut))completion
{
    // Ask confirmation
    self.logoutConfirmation = [UIAlertController alertControllerWithTitle:[VectorL10n errorUserAlreadyLoggedIn]
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleAlert];

    [self.logoutConfirmation addAction:[UIAlertAction actionWithTitle:[VectorL10n settingsSignOut]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action)
                                        {
        self.logoutConfirmation = nil;
        [self logoutWithConfirmation:NO completion:^(BOOL isLoggedOut) {
            if (isLoggedOut)
            {
                //  process the link again after logging out
                [AuthenticationService.shared handleServerProvisioningLink:link];
            }
            if (completion)
            {
                completion(YES);
            }
        }];
    }]];

    [self.logoutConfirmation addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                                style:UIAlertActionStyleCancel
                                                              handler:^(UIAlertAction * action)
                                        {
        self.logoutConfirmation = nil;
        if (completion)
        {
            completion(NO);
        }
    }]];

    [self.logoutConfirmation mxk_setAccessibilityIdentifier:@"AppDelegateLogoutConfirmationAlert"];
    [self showNotificationAlert:self.logoutConfirmation];
}

#pragma mark - Matrix sessions handling

// TODO: Move this method content in UserSessionsService
- (void)initMatrixSessions
{
    MXLogDebug(@"[AppDelegate] initMatrixSessions");

    // Set first RoomDataSource class used in Vector
    [MXKRoomDataSourceManager registerRoomDataSourceClass:RoomDataSource.class];
    
    // Register matrix session state observer in order to handle multi-sessions.
    matrixSessionStateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        MXSession *mxSession = (MXSession*)notif.object;
        
        // Check whether the concerned session is a new one
        if (mxSession.state == MXSessionStateInitialised)
        {
            // Store this new session
            [self addMatrixSession:mxSession];
            
            [self configureCallManagerIfRequiredForSession:mxSession];
            
            [self.configuration setupSettingsFor:mxSession];                                    
        }
        else if (mxSession.state == MXSessionStateStoreDataReady)
        {
            //  start the call service
            [self.callPresenter start];
            
            [self.configuration setupSettingsWhenLoadedFor:mxSession];
            
            // Register to user new device sign in notification
            [self registerUserDidSignInOnNewDeviceNotificationForSession:mxSession];
            
            [self registerDidChangeCrossSigningKeysNotificationForSession:mxSession];
            
            // Register to new key verification request
            [self registerNewRequestNotificationForSession:mxSession];
            
            [self checkLocalPrivateKeysInSession:mxSession];
            
            [self.pushNotificationService checkPushKitPushersInSession:mxSession];
        }
        else if (mxSession.state == MXSessionStateRunning)
        {
            // Configure analytics from the session if necessary
            [Analytics.shared useAnalyticsSettingsFrom:mxSession];
        }
        else if (mxSession.state == MXSessionStateClosed)
        {
            [self removeMatrixSession:mxSession];
        }
        
        [self handleAppState];
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
            account.pushGatewayURL = BuildSettings.serverConfigSygnalAPIUrlString;

            BOOL isPushRegistered = self.pushNotificationService.isPushRegistered;

            MXLogDebug(@"[AppDelegate][Push] didAddAccountNotification: isPushRegistered: %@", @(isPushRegistered));

            if (isPushRegistered)
            {
                // Enable push notifications by default on new added account
                [account enablePushNotifications:YES success:nil failure:nil];
            }
            else
            {
                // Set up push notifications
                [self.pushNotificationService registerUserNotificationSettings];
            }
        }
        
        [self.delegate legacyAppDelegate:self didAddAccount:account];
    }];
    
    // Add observer to handle removed accounts
    removedAccountObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidRemoveAccountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        // Remove inApp notifications toggle change
        MXKAccount *account = notif.object;

        // Clear Modular data
        [[WidgetManager sharedManager] deleteDataForUser:account.mxCredentials.userId];
        
        // Logout the app when there is no available account
        if (![MXKAccountManager sharedManager].accounts.count)
        {
            [self logoutWithConfirmation:NO completion:nil];
        }
        
        [self.delegate legacyAppDelegate:self didRemoveAccount:account];
    }];

    // Add observer to handle soft logout
    [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidSoftlogoutAccountNotification  object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

        MXKAccount *account = notif.object;
        
        if (account.mxSession)
        {
            [self removeMatrixSession:account.mxSession];
        }

        // Return to authentication screen
        [self.masterTabBarController showSoftLogoutOnboardingFlowWithCredentials:account.mxCredentials];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionIgnoredUsersDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notif) {
        
        MXLogDebug(@"[AppDelegate] kMXSessionIgnoredUsersDidChangeNotification received. Reload the app");
        
        // Reload entirely the app when a user has been ignored or unignored
        [[AppDelegate theDelegate] reloadMatrixSessions:YES];
        
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionDidCorruptDataNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notif) {
        
        MXLogDebug(@"[AppDelegate] kMXSessionDidCorruptDataNotification received. Reload the app");
        
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
    MXLogDebug(@"[AppDelegate] initMatrixSessions: prepareSessionForActiveAccounts (app state: %tu)", [[UIApplication sharedApplication] applicationState]);
    [accountManager prepareSessionForActiveAccounts];
    
    // Check whether we're already logged in
    NSArray *mxAccounts = accountManager.activeAccounts;
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
                account.pushGatewayURL = BuildSettings.serverConfigSygnalAPIUrlString;
            }
        }
        
        // Set up push notifications
        [self.pushNotificationService registerUserNotificationSettings];
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
        // But wait a bit that our launch animation screen is ready to show and
        // displayed if needed. As the processing in MXKContactManager can lock
        // the UI thread for several seconds, it is better to show the animation
        // during this blocking task.
        dispatch_after(dispatch_walltime(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [[MXKContactManager sharedManager] addMatrixSession:mxSession];
        });

        // Register the session to the widgets manager
        [[WidgetManager sharedManager] addMatrixSession:mxSession];
        
        // register the session to the call service
        [_callPresenter addMatrixSession:mxSession];
        
        // register the session to the uisi auto-reporter
        if (_uisiAutoReporter != nil)
        {
            UISIAutoReporter* uisiAutoReporter = (UISIAutoReporter*)_uisiAutoReporter;
            [uisiAutoReporter add:mxSession];
        }
        
        [mxSessionArray addObject:mxSession];
        
        // Do the one time check on device id
        [self checkDeviceId:mxSession];
        
        [self.delegate legacyAppDelegate:self didAddMatrixSession:mxSession];
    }
}

- (void)removeMatrixSession:(MXSession*)mxSession
{
    [[MXKContactManager sharedManager] removeMatrixSession:mxSession];
    
    // remove session from the call service
    [_callPresenter removeMatrixSession:mxSession];
    
    // register the session to the uisi auto-reporter
    if (_uisiAutoReporter != nil)
    {
        UISIAutoReporter* uisiAutoReporter = (UISIAutoReporter*)_uisiAutoReporter;
        [uisiAutoReporter remove:mxSession];
    }

    // Update the widgets manager
    [[WidgetManager sharedManager] removeMatrixSession:mxSession]; 
    
    // If any, disable the no VoIP support workaround
    [self disableNoVoIPOnMatrixSession:mxSession];

    // Disable listening of incoming key share requests
    [self disableRoomKeyRequestObserver:mxSession];

    // Disable listening of incoming key verification requests
    [self disableIncomingKeyVerificationObserver:mxSession];

    [mxSessionArray removeObject:mxSession];
    
    if (!mxSessionArray.count)
    {
        //  if no session left, stop the call service
        [self.callPresenter stop];
    }
    
    [self.delegate legacyAppDelegate:self didRemoveMatrixSession:mxSession];
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
        self.clearingCache = YES;
        [self clearCache];
    }
}

- (void)logoutWithConfirmation:(BOOL)askConfirmation completion:(void (^)(BOOL isLoggedOut))completion
{
    // Check whether we have to ask confirmation before logging out.
    if (askConfirmation)
    {
        if (self.logoutConfirmation)
        {
            [self.logoutConfirmation dismissViewControllerAnimated:NO completion:nil];
            self.logoutConfirmation = nil;
        }
        
        __weak typeof(self) weakSelf = self;
        
        NSString *message = [VectorL10n settingsSignOutConfirmation];
        
        // If the user has encrypted rooms, warn he will lose his e2e keys
        MXSession *session = self.mxSessions.firstObject;
        for (MXRoom *room in session.rooms)
        {
            if (room.summary.isEncrypted)
            {
                message = [message stringByAppendingString:[NSString stringWithFormat:@"\n\n%@", [VectorL10n settingsSignOutE2eWarn]]];
                break;
            }
        }
        
        // Ask confirmation
        self.logoutConfirmation = [UIAlertController alertControllerWithTitle:[VectorL10n settingsSignOut] message:message preferredStyle:UIAlertControllerStyleAlert];
        
        [self.logoutConfirmation addAction:[UIAlertAction actionWithTitle:[VectorL10n settingsSignOut]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               self.logoutConfirmation = nil;
                                                               
                                                               dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                                                   
                                                                   [self logoutWithConfirmation:NO completion:completion];
                                                                   
                                                               });
                                                           }
                                                           
                                                       }]];
        
        [self.logoutConfirmation addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               self.logoutConfirmation = nil;
                                                               
                                                               if (completion)
                                                               {
                                                                   completion(NO);
                                                               }
                                                           }
                                                           
                                                       }]];
        
        [self.logoutConfirmation mxk_setAccessibilityIdentifier: @"AppDelegateLogoutConfirmationAlert"];
        [self showNotificationAlert:self.logoutConfirmation];
        return;
    }
    
    // Display a loading wheel during the logout process
    id topVC;
    if (_masterTabBarController && _masterTabBarController == _masterNavigationController.visibleViewController)
    {
        topVC = _masterTabBarController.selectedViewController;
    }
    else
    {
        topVC = _masterNavigationController.visibleViewController;
    }
    if (topVC && [topVC respondsToSelector:@selector(startActivityIndicator)])
    {
        [topVC startActivityIndicator];
    }
    
    [self logoutSendingRequestServer:YES completion:^(BOOL isLoggedOut) {
        if (completion)
        {
            completion (YES);
        }
    }];
}

- (void)logoutSendingRequestServer:(BOOL)sendLogoutServerRequest
                        completion:(void (^)(BOOL isLoggedOut))completion
{
    MXSession *mainSession = self.mxSessions.firstObject;
    [mainSession close];

    [self.pushNotificationService deregisterRemoteNotifications];

    // Clear cache
    [self clearCache];
    
    // Reset key backup banner preferences
    [SecureBackupBannerPreferences.shared reset];
    
    // Reset key verification banner preferences
    [CrossSigningBannerPreferences.shared reset];
    
    // Reset user pin code
    [PinCodePreferences.shared reset];
    
    //  Reset push notification store
    [self.pushNotificationStore reset];
    
    // Reset analytics
    [Analytics.shared reset];
    
    [[[ReviewSessionAlertSnoozeController alloc] init] clearSnooze];
    
    [TimelinePollProvider.shared reset];
    
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
    [[MXKAccountManager sharedManager] logoutWithCompletion:^{
        
        // We reset allChatsOnboardingHasBeenDisplayed flag on logout
        RiotSettings.shared.allChatsOnboardingHasBeenDisplayed = NO;
        
        if (completion)
        {
            completion (YES);
        }
        
        // Return to authentication screen
        [self->_masterTabBarController showOnboardingFlow];
        
        // Note: Keep App settings
        // But enforce usage of member lazy loading
        [MXKAppSettings standardAppSettings].syncWithLazyLoadOfRoomMembers = YES;
        
        // Reset the contact manager
        [[MXKContactManager sharedManager] reset];
        
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([@"showAllEventsInRoomHistory" isEqualToString:keyPath])
    {
        // Flush and restore Matrix data
        [self reloadMatrixSessions:NO];
    }
    else if (object == [MXKAppSettings standardAppSettings] && [keyPath isEqualToString:@"enableCallKit"])
    {
        BOOL isCallKitEnabled = [MXKAppSettings standardAppSettings].isCallKitEnabled;
        MXCallManager *callManager = [[[[[MXKAccountManager sharedManager] activeAccounts] firstObject] mxSession] callManager];
        [self enableCallKit:isCallKitEnabled forCallManager:callManager];
    }
}

- (void)handleAppState
{
    MXSession *mainSession = self.mxSessions.firstObject;
    
    if (mainSession)
    {
        switch (mainSession.state)
        {
            case MXSessionStateClosed:
            case MXSessionStateInitialised:
                self.roomListDataReady = NO;
                [self listenForRoomListDataReady];
            default:
                break;
        }
        
        BOOL isLaunching = NO;

        if (mainSession.vc_homeserverConfiguration)
        {
            [MXKAppSettings standardAppSettings].outboundGroupSessionKeyPreSharingStrategy = mainSession.vc_homeserverConfiguration.encryption.outboundKeysPreSharingMode;
        }
        
        if (_masterTabBarController.isOnboardingInProgress)
        {
            MXLogDebug(@"[AppDelegate] handleAppState: Authentication still in progress");
                  
            // Wait for the return of masterTabBarControllerDidCompleteAuthentication
            isLaunching = YES;            
        }
        else
        {
            MXLogDebug(@"[AppDelegate] handleAppState: mainSession.state: %@", [MXTools readableSessionState:mainSession.state]);
            switch (mainSession.state)
            {
                case MXSessionStateClosed:
                case MXSessionStateInitialised:
                    isLaunching = YES;
                    break;
                case MXSessionStateStoreDataReady:
                case MXSessionStateProcessingBackgroundSyncCache:
                case MXSessionStateSyncInProgress:
                    // Stay in launching during the first server sync if the store is empty.
                    isLaunching = (mainSession.rooms.count == 0 && launchAnimationContainerView);
                    
                    if (mainSession.crypto.crossSigning && mainSession.crypto.crossSigning.state == MXCrossSigningStateCrossSigningExists && [mainSession.crypto isKindOfClass:[MXLegacyCrypto class]])
                    {
                        [(MXLegacyCrypto *)mainSession.crypto setOutgoingKeyRequestsEnabled:NO onComplete:nil];
                    }
                    break;
                case MXSessionStateRunning:
                    self.clearingCache = NO;
                    isLaunching = NO;
                    break;
                default:
                    isLaunching = NO;
                    break;
            }
        }
        
        MXLogDebug(@"[AppDelegate] handleAppState: isLaunching: %@", isLaunching ? @"YES" : @"NO");
        
        if (self.masterTabBarController.isOnboardingInProgress)
        {
            MXLogDebug(@"[AppDelegate] handleAppState: Skipping LaunchLoadingView due to Onboarding.");
            return;
        }
        
        if (isLaunching)
        {
            MXLogDebug(@"[AppDelegate] handleAppState: LaunchLoadingView");
            [self showLaunchAnimation];
            return;
        }
        
        if (self.isClearingCache)
        {
            //  wait for another session state change to check room list data is ready
            return;
        }

        if (mainSession.vc_homeserverConfiguration.encryption.isSecureBackupRequired
            && mainSession.state == MXSessionStateRunning
            && mainSession.vc_canSetupSecureBackup)
        {
            // This only happens at the first login
            // Or when migrating an existing user
            MXLogDebug(@"[AppDelegate] handleAppState: Force SSSS setup");
            [self presentSecureBackupSetupForSession:mainSession];
        }
        
        void (^finishAppLaunch)(void) = ^{
            [self hideLaunchAnimation];
            
            if (self.setPinCoordinatorBridgePresenter)
            {
                MXLogDebug(@"[AppDelegate] handleAppState: PIN code is presented. Do not go further");
                return;
            }
            
            MXLogDebug(@"[AppDelegate] handleAppState: Check cross-signing");
            [self checkCrossSigningForSession:mainSession];
            
            // TODO: We should wait that cross-signing screens are done before going further but it seems fine. Those screens
            // protect each other.
            
            // This is the time to check existing requests
            MXLogDebug(@"[AppDelegate] handleAppState: Check pending verification requests");
            [self checkPendingRoomKeyRequests];
            [self checkPendingIncomingKeyVerificationsInSession:mainSession];
                
            // TODO: When we will have an application state, we will do all of this in a dedicated initialisation state
            // For the moment, reuse an existing boolean to avoid register things several times
            if (!self->incomingKeyVerificationObserver)
            {
                MXLogDebug(@"[AppDelegate] handleAppState: Set up observers for the crypto module");
                
                // Enable listening of incoming key share requests
                [self enableRoomKeyRequestObserver:mainSession];
                
                // Enable listening of incoming key verification requests
                [self enableIncomingKeyVerificationObserver:mainSession];
            }
        };
        
        if (self.isRoomListDataReady)
        {
            finishAppLaunch();
        }
        else
        {
            // An observer has been set in didFinishLaunching that will call the stored block when ready
            self.roomListDataReadyCompletion = finishAppLaunch;
        }
    }
}

- (void)showLaunchAnimation
{
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    
    if (!launchAnimationContainerView && window)
    {
        MXLogDebug(@"[AppDelegate] showLaunchAnimation");
        
        LaunchLoadingView *launchLoadingView;
        if (MXSDKOptions.sharedInstance.enableSyncProgress)
        {
            MXSession *mainSession = self.mxSessions.firstObject;
            launchLoadingView = [LaunchLoadingView instantiateWithSyncProgress:mainSession.syncProgress];
        }
        else
        {
            launchLoadingView = [LaunchLoadingView instantiateWithSyncProgress:nil];
        }
                
        launchLoadingView.frame = window.bounds;
        [launchLoadingView updateWithTheme:ThemeService.shared.theme];
        launchLoadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [window addSubview:launchLoadingView];
        
        launchAnimationContainerView = launchLoadingView;
        
        [MXSDKOptions.sharedInstance.profiler startMeasuringTaskWithName:MXTaskProfileNameStartupLaunchScreen];
    }
}

- (void)hideLaunchAnimation
{
    if (launchAnimationContainerView)
    {
        id<MXProfiler> profiler = MXSDKOptions.sharedInstance.profiler;
        MXTaskProfile *launchTaskProfile = [profiler taskProfileWithName:MXTaskProfileNameStartupLaunchScreen];
        if (launchTaskProfile)
        {
            [profiler stopMeasuringTaskWithProfile:launchTaskProfile];
            
            MXLogDebug(@"[AppDelegate] hideLaunchAnimation: LaunchAnimation was shown for %.3fms", launchTaskProfile.duration * 1000);
        }
        
        [self->launchAnimationContainerView removeFromSuperview];
        self->launchAnimationContainerView = nil;
    }
}

- (void)configureCallManagerIfRequiredForSession:(MXSession *)mxSession
{
    if (mxSession.callManager)
    {
        //  already configured
        return;
    }
    
    // Set the VoIP call stack (if supported).
    id<MXCallStack> callStack;
    
#ifdef MX_CALL_STACK_OPENWEBRTC
    callStack = [[MXOpenWebRTCCallStack alloc] init];
#endif
#ifdef MX_CALL_STACK_ENDPOINT
    callStack = [[MXEndpointCallStack alloc] initWithMatrixId:mxSession.myUser.userId];
#endif
#ifdef CALL_STACK_JINGLE
    callStack = [[MXJingleCallStack alloc] init];
#endif
    
    if (callStack)
    {
        [mxSession enableVoIPWithCallStack:callStack];
        
        // Setup CallKit
        if ([MXCallKitAdapter callKitAvailable])
        {
            BOOL isCallKitEnabled = [MXKAppSettings standardAppSettings].isCallKitEnabled;
            [self enableCallKit:isCallKitEnabled forCallManager:mxSession.callManager];
            
            // Register for changes performed by the user
            [[MXKAppSettings standardAppSettings] addObserver:self
                                                   forKeyPath:@"enableCallKit"
                                                      options:NSKeyValueObservingOptionNew
                                                      context:NULL];
        }
        else
        {
            [self enableCallKit:NO forCallManager:mxSession.callManager];
        }
    }
    else
    {
        // When there is no call stack, display alerts on call invites
        [self enableNoVoIPOnMatrixSession:mxSession];
    }
}

- (void)enableCallKit:(BOOL)enable forCallManager:(MXCallManager *)callManager
{
#ifdef CALL_STACK_JINGLE
    JitsiService.shared.enableCallKit = enable;
    
    if (enable)
    {
        // Create adapter for Riot
        MXCallKitConfiguration *callKitConfiguration = [[MXCallKitConfiguration alloc] init];
        callKitConfiguration.iconName = @"callkit_icon";
        
        NSData *riotCallKitIconData = UIImagePNGRepresentation([UIImage imageNamed:callKitConfiguration.iconName]);
        [JitsiService.shared configureCallKitProviderWithLocalizedName:callKitConfiguration.name
                                                          ringtoneName:callKitConfiguration.ringtoneName
                                                 iconTemplateImageData:riotCallKitIconData];

        MXCallKitAdapter *callKitAdapter = [[MXCallKitAdapter alloc] initWithConfiguration:callKitConfiguration];
        
        id<MXCallAudioSessionConfigurator> audioSessionConfigurator;
        
        audioSessionConfigurator = [[MXJingleCallAudioSessionConfigurator alloc] init];
        
        callKitAdapter.audioSessionConfigurator = audioSessionConfigurator;
        
        callManager.callKitAdapter = callKitAdapter;
    }
    else
    {
        callManager.callKitAdapter = nil;
    }
#endif
}

- (void)checkLocalPrivateKeysInSession:(MXSession*)mxSession
{
    if (![mxSession.crypto isKindOfClass:[MXLegacyCrypto class]])
    {
        return;
    }
    MXLegacyCrypto *crypto = (MXLegacyCrypto *)mxSession.crypto;
    
    MXRecoveryService *recoveryService = mxSession.crypto.recoveryService;
    NSUInteger keysCount = 0;
    if ([recoveryService hasSecretWithSecretId:MXSecretId.keyBackup])
    {
        keysCount++;
    }
    if ([recoveryService hasSecretWithSecretId:MXSecretId.crossSigningUserSigning])
    {
        keysCount++;
    }
    if ([recoveryService hasSecretWithSecretId:MXSecretId.crossSigningSelfSigning])
    {
        keysCount++;
    }
    
    if ((keysCount > 0 && keysCount < 3)
        || (mxSession.crypto.crossSigning.canTrustCrossSigning && !mxSession.crypto.crossSigning.canCrossSign))
    {
        // We should have 3 of them. If not, request them again as mitigation
        MXLogDebug(@"[AppDelegate] checkLocalPrivateKeysInSession: request keys because keysCount = %@", @(keysCount));
        [crypto requestAllPrivateKeys];
    }
}

- (void)authenticationDidComplete
{
    [self handleAppState];
}

- (void)listenForRoomListDataReady
{
    if (self.roomListDataReadyObserver)
    {
        return;
    }
    
    MXWeakify(self);
    NSNotificationCenter * __weak notificationCenter = [NSNotificationCenter defaultCenter];
    self.roomListDataReadyObserver = [[NSNotificationCenter defaultCenter] addObserverForName:RecentsViewControllerDataReadyNotification
                                                                            object:nil
                                                                             queue:[NSOperationQueue mainQueue]
                                                                        usingBlock:^(NSNotification * _Nonnull notification) {
        MXStrongifyAndReturnIfNil(self);
        
        [notificationCenter removeObserver:self.roomListDataReadyObserver];
        self.roomListDataReady = YES;
        self.roomListDataReadyObserver = nil;
        
        if (self.roomListDataReadyCompletion)
        {
            self.roomListDataReadyCompletion();
            self.roomListDataReadyCompletion = nil;
        }
    }];
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
        
        // Check if there is a device id
        if (!mxSession.matrixRestClient.credentials.deviceId)
        {
            MXLogDebug(@"WARNING: The user has no device. Prompt for login again");
            
            NSString *msg = [VectorL10n e2eEnablingOnAppUpdate:AppInfo.current.displayName];
            
            __weak typeof(self) weakSelf = self;
            [_errorNotification dismissViewControllerAnimated:NO completion:nil];
            _errorNotification = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
            
            [_errorNotification addAction:[UIAlertAction actionWithTitle:[VectorL10n later]
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                     
                                                                     if (weakSelf)
                                                                     {
                                                                         typeof(self) self = weakSelf;
                                                                         self->_errorNotification = nil;
                                                                     }
                                                                     
                                                                 }]];
            
            [_errorNotification addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                     
                                                                     if (weakSelf)
                                                                     {
                                                                         typeof(self) self = weakSelf;
                                                                         self->_errorNotification = nil;
                                                                         
                                                                         [self logoutWithConfirmation:NO completion:nil];
                                                                     }
                                                                     
                                                                 }]];
            
            // Prompt the user
            [_errorNotification mxk_setAccessibilityIdentifier:@"AppDelegateErrorAlert"];
            [self showNotificationAlert:_errorNotification];
        }
    }
}

- (void)presentViewController:(UIViewController*)viewController
                     animated:(BOOL)animated
                   completion:(void (^)(void))completion
{
    [self.presentedViewController presentViewController:viewController animated:animated completion:completion];
}

- (UIViewController*)presentedViewController
{
    return self.window.rootViewController.presentedViewController ?: self.window.rootViewController;
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
        [accountPicker dismissViewControllerAnimated:NO completion:nil];
        
        accountPicker = [UIAlertController alertControllerWithTitle:[VectorL10n selectAccount] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
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
        
        [accountPicker addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                          style:UIAlertActionStyleCancel
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

- (void)navigateToRoomById:(NSString *)roomId threadId:(NSString *)threadId sender:(NSString *)userId
{
    if (roomId.length)
    {
        // TODO retrieve the right matrix session
        // We can use the "user_id" value in notification.userInfo

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
            MXLogDebug(@"[AppDelegate][Push] navigateToRoomById: open the roomViewController %@", roomId);

            [self showRoom:roomId
                  threadId:threadId
                andEventId:nil
         withMatrixSession:dedicatedAccount.mxSession
                    sender:userId];
        }
        else
        {
            MXLogDebug(@"[AppDelegate][Push] navigateToRoomById : no linked session / account has been found.");
        }
    }
}

- (void)showRoomWithParameters:(RoomNavigationParameters*)parameters
{
    [self showRoomWithParameters:parameters completion:nil];
}

- (void)showRoomWithParameters:(RoomNavigationParameters*)parameters completion:(void (^)(void))completion
{
    NSString *roomId = parameters.roomId;
    MXSession *mxSession = parameters.mxSession;
    
    if (roomId && mxSession)
    {
        MXRoom *room = [mxSession roomWithRoomId:roomId];
        
        if (room && room.summary.membership == MXMembershipJoin)
        {
            [Analytics.shared trackViewRoom:room];
        }

        if (!room)
        {
            MXWeakify(self);
            [mxSession.matrixRestClient roomSummaryWith:roomId via:@[] success:^(MXPublicRoom *room) {
                MXStrongifyAndReturnIfNil(self);
                if ([room.roomTypeString isEqualToString:MXRoomTypeStringSpace])
                {
                    SpacePreviewNavigationParameters *spacePreviewNavigationParameters = [[SpacePreviewNavigationParameters alloc] initWithPublicRoom:room mxSession:mxSession senderId:parameters.senderId presentationParameters:parameters.presentationParameters];
                    [self showSpacePreviewWithParameters:spacePreviewNavigationParameters];
                }
                else
                {
                    [self finaliseShowRoomWithParameters:parameters completion:completion];
                }
            } failure:^(NSError *error) {
                MXStrongifyAndReturnIfNil(self);
                [self finaliseShowRoomWithParameters:parameters completion:completion];
            }];
            
            return;
        }
        
    }
    
    [self finaliseShowRoomWithParameters:parameters completion:completion];
}

- (void)finaliseShowRoomWithParameters:(RoomNavigationParameters*)parameters completion:(void (^)(void))completion
{
    NSString *roomId = parameters.roomId;
    BOOL restoreInitialDisplay = parameters.presentationParameters.restoreInitialDisplay;

    void (^selectRoom)(void) = ^() {
        // Select room to display its details (dispatch this action in order to let TabBarController end its refresh)
        
        [self.masterTabBarController selectRoomWithParameters:parameters completion:^{
            // Remove delivered notifications for this room
            [self.pushNotificationService removeDeliveredNotificationsWithRoomId:roomId completion:nil];
            
            if (completion)
            {
                completion();
            }
        }];
    };
    
    if (restoreInitialDisplay)
    {
        [self restoreInitialDisplay:^{
            selectRoom();
        }];
    }
    else
    {
        selectRoom();
    }
}

- (void)showRoom:(NSString*)roomId andEventId:(NSString*)eventId withMatrixSession:(MXSession*)mxSession
{
    [self showRoom:roomId threadId:nil andEventId:eventId withMatrixSession:mxSession sender:nil];
}

- (void)showRoom:(NSString*)roomId threadId:(NSString*)threadId andEventId:(NSString*)eventId withMatrixSession:(MXSession*)mxSession sender:(NSString*)userId
{
    // Ask to restore initial display
    ScreenPresentationParameters *presentationParameters = [[ScreenPresentationParameters alloc] initWithRestoreInitialDisplay:YES];

    ThreadParameters *threadParameters = nil;
    if (RiotSettings.shared.enableThreads && threadId)
    {
        threadParameters = [[ThreadParameters alloc] initWithThreadId:threadId stackRoomScreen:NO];
    }

    RoomNavigationParameters *parameters = [[RoomNavigationParameters alloc] initWithRoomId:roomId
                                                                                    eventId:eventId
                                                                                  mxSession:mxSession
                                                                                   senderId:userId
                                                                           threadParameters:threadParameters
                                                                     presentationParameters:presentationParameters];
    
    [self showRoomWithParameters:parameters];
}

- (void)showNewDirectChat:(NSString*)userId withMatrixSession:(MXSession*)mxSession completion:(void (^)(void))completion
{
    // Ask to restore initial display
    ScreenPresentationParameters *presentationParameters = [[ScreenPresentationParameters alloc] initWithRestoreInitialDisplay:YES];
    
    RoomNavigationParameters *parameters = [[RoomNavigationParameters alloc] initWithUserId:userId
                                                                                  mxSession:mxSession
                                                                     presentationParameters:presentationParameters];
    
    [self showRoomWithParameters:parameters completion:completion];
}

- (void)showRoomPreviewWithParameters:(RoomPreviewNavigationParameters*)parameters completion:(void (^)(void))completion
{
    void (^showRoomPreview)(void) = ^() {
        [self.masterTabBarController selectRoomPreviewWithParameters:parameters completion:completion];
    };
    
    if (parameters.presentationParameters.restoreInitialDisplay)
    {
        [self restoreInitialDisplay:^{
            showRoomPreview();
        }];
    }
    else
    {
        showRoomPreview();
    }
}

- (void)showRoomPreviewWithParameters:(RoomPreviewNavigationParameters*)parameters
{
    [self showRoomPreviewWithParameters:parameters completion:nil];
}

- (void)showRoomPreview:(RoomPreviewData*)roomPreviewData
{
    // Ask to restore initial display
    ScreenPresentationParameters *presentationParameters = [[ScreenPresentationParameters alloc] initWithRestoreInitialDisplay:YES];
    
    RoomPreviewNavigationParameters *parameters = [[RoomPreviewNavigationParameters alloc] initWithPreviewData:roomPreviewData presentationParameters:presentationParameters];
    
    [self showRoomPreviewWithParameters:parameters];
}

- (void)showSpacePreviewWithParameters:(SpacePreviewNavigationParameters*)parameters
{
    UIViewController *presentingViewController;
    UIView *sourceView;
    
    if (parameters.presentationParameters.presentingViewController)
    {
        presentingViewController = parameters.presentationParameters.presentingViewController;
        sourceView = parameters.presentationParameters.sourceView;
    }
    else
    {
        presentingViewController = self.masterNavigationController;
    }
    
    self.spaceDetailPresenter = [SpaceDetailPresenter new];
    self.spaceDetailPresenter.delegate = self;
    
    void(^showSpace)(void) = ^{
        [self.spaceDetailPresenter presentForSpaceWithPublicRoom:parameters.publicRoom
                                                        senderId:parameters.senderId
                                                            from:presentingViewController
                                                      sourceView:sourceView
                                                         session:parameters.mxSession 
                                                        animated:YES];
    };
    
    if (parameters.presentationParameters.restoreInitialDisplay)
    {
        [self restoreInitialDisplay:^{
            showSpace();
        }];
    }
    else
    {
        showSpace();
    }
}

- (void)showSpaceWithParameters:(SpaceNavigationParameters*)parameters
{
    UIViewController *presentingViewController;
    UIView *sourceView;
    
    if (parameters.presentationParameters.presentingViewController)
    {
        presentingViewController = parameters.presentationParameters.presentingViewController;
        sourceView = parameters.presentationParameters.sourceView;
    }
    else
    {
        presentingViewController = self.masterNavigationController;
    }

    self.spaceDetailPresenter = [SpaceDetailPresenter new];
    self.spaceDetailPresenter.delegate = self;
    
    void(^showSpace)(void) = ^{
        [self.spaceDetailPresenter presentForSpaceWithId:parameters.roomId
                                                    from:presentingViewController
                                              sourceView:sourceView
                                                 session:parameters.mxSession
                                                animated:YES];
    };
    
    if (parameters.presentationParameters.restoreInitialDisplay)
    {
        [self restoreInitialDisplay:^{
            showSpace();
        }];
    }
    else
    {
        showSpace();
    }
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

- (void)createDirectChatWithUserId:(NSString*)userId completion:(void (^)(NSString *roomId))completion
{
    // Handle here potential multiple accounts
    [self selectMatrixAccount:^(MXKAccount *selectedAccount) {
        
        MXSession *mxSession = selectedAccount.mxSession;
        
        if (mxSession)
        {
            // Create a new room by inviting the other user only if it is defined and not oneself
            NSArray *invite = ((userId && ![mxSession.myUser.userId isEqualToString:userId]) ? @[userId] : nil);

            void (^onFailure)(NSError *) = ^(NSError *error){
                MXLogDebug(@"[AppDelegate] Create direct chat failed");
                //Alert user
                [self showAlertWithTitle:nil message:[VectorL10n roomCreationDmError]];

                if (completion)
                {
                    completion(nil);
                }
            };

            [mxSession vc_canEnableE2EByDefaultInNewRoomWithUsers:invite success:^(BOOL canEnableE2E) {
                
                MXRoomCreationParameters *roomCreationParameters = [MXRoomCreationParameters new];
                roomCreationParameters.visibility = kMXRoomDirectoryVisibilityPrivate;
                roomCreationParameters.inviteArray = invite;
                roomCreationParameters.isDirect = (invite.count != 0);
                roomCreationParameters.preset = kMXRoomPresetTrustedPrivateChat;

                if (canEnableE2E)
                {
                    roomCreationParameters.initialStateEvents = @[
                                                                  [MXRoomCreationParameters initialStateEventForEncryptionWithAlgorithm:kMXCryptoMegolmAlgorithm
                                                                  ]];
                }

                [mxSession createRoomWithParameters:roomCreationParameters success:^(MXRoom *room) {

                    // Room is created
                    Analytics.shared.viewRoomTrigger = AnalyticsViewRoomTriggerCreated;

                    if (completion)
                    {
                        completion(room.roomId);
                    }

                } failure:onFailure];

            } failure:onFailure];
        }
        else if (completion)
        {
            completion(nil);
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
                Analytics.shared.viewRoomTrigger = AnalyticsViewRoomTriggerCreated;
                [self showRoom:directRoom.roomId andEventId:nil withMatrixSession:mxSession];
                
                if (completion)
                {
                    completion();
                }
            }
            else
            {
                [self showNewDirectChat:userId withMatrixSession:mxSession completion:completion];
            }
        }
        else if (completion)
        {
            completion();
        }
        
    }];
}

#pragma mark - Contacts handling

- (void)showContact:(MXKContact*)contact presentationParameters:(ScreenPresentationParameters*)presentationParameters
{
    void(^showContact)(void) = ^{
        [self.masterTabBarController selectContact:contact withPresentationParameters:presentationParameters];
    };
    
    if (presentationParameters.restoreInitialDisplay)
    {
        [self restoreInitialDisplay:^{
            showContact();
        }];
    }
    else
    {
        showContact();
    }
}

#pragma mark - VoIP

- (void)promptForStunServerFallback
{
    [_errorNotification dismissViewControllerAnimated:NO completion:nil];

    NSString *stunFallbackHost = BuildSettings.stunServerFallbackUrlString;
    // Remove "stun:"
    stunFallbackHost = [stunFallbackHost componentsSeparatedByString:@":"].lastObject;

    MXSession *mainSession = self.mxSessions.firstObject;
    NSString *homeServerName = mainSession.matrixRestClient.credentials.homeServerName;

    NSString *message = [NSString stringWithFormat:@"%@\n\n%@",
                         [VectorL10n callNoStunServerErrorMessage1:homeServerName],
                         [VectorL10n callNoStunServerErrorMessage2:stunFallbackHost]];
    
    _errorNotification = [UIAlertController alertControllerWithTitle:[VectorL10n callNoStunServerErrorTitle]
                                                             message:message
                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [_errorNotification addAction:[UIAlertAction actionWithTitle:[VectorL10n callNoStunServerErrorUseFallbackButton:stunFallbackHost]
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
        
        RiotSettings.shared.allowStunServerFallback = YES;
                                                             mainSession.callManager.fallbackSTUNServer = BuildSettings.stunServerFallbackUrlString;

                                                             [AppDelegate theDelegate].errorNotification = nil;
                                                         }]];

    [_errorNotification addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {

                                                             RiotSettings.shared.allowStunServerFallback = NO;

                                                             [AppDelegate theDelegate].errorNotification = nil;
                                                         }]];

    // Display the error notification
    if (!isErrorNotificationSuspended)
    {
        [_errorNotification mxk_setAccessibilityIdentifier:@"AppDelegateErrorAlert"];
        [self showNotificationAlert:_errorNotification];
    }
}

#pragma mark - Native Widget Permission

- (void)checkPermissionForNativeWidget:(Widget*)widget fromUrl:(NSURL*)url completion:(void (^)(BOOL granted))completion
{
    MXSession *session = widget.mxSession;

    if ([widget.widgetEvent.sender isEqualToString:session.myUser.userId])
    {
        // No need of more permission check if the user created the widget
        completion(YES);
        return;
    }

    // Check permission in user Riot settings
    __block RiotSharedSettings *sharedSettings = [[RiotSharedSettings alloc] initWithSession:session];

    WidgetPermission permission = [sharedSettings permissionForNative:widget fromUrl:url];
    if (permission == WidgetPermissionGranted)
    {
        completion(YES);
    }
    else
    {
        // Note: ask permission again if the user previously declined it
        [self askNativeWidgetPermissionWithWidget:widget completion:^(BOOL granted) {
            // Update the settings in user account data in parallel
            [sharedSettings setPermission:granted ? WidgetPermissionGranted : WidgetPermissionDeclined
                                forNative:widget fromUrl:url
                                  success:^
             {
                 sharedSettings = nil;
             }
                                  failure:^(NSError * _Nullable error)
             {
                MXLogDebug(@"[WidgetVC] setPermissionForWidget failed. Error: %@", error);
                 sharedSettings = nil;
             }];
            
            completion(granted);
        }];
    }
}

- (void)askNativeWidgetPermissionWithWidget:(Widget*)widget completion:(void (^)(BOOL granted))completion
{
    if (!self.slidingModalPresenter)
    {
        self.slidingModalPresenter = [SlidingModalPresenter new];
    }
    
    [self.slidingModalPresenter dismissWithAnimated:NO completion:nil];
    
    NSString *widgetCreatorUserId = widget.widgetEvent.sender ?: [VectorL10n roomParticipantsUnknown];
    
    MXSession *session = widget.mxSession;
    MXRoom *room = [session roomWithRoomId:widget.widgetEvent.roomId];
    MXRoomState *roomState = room.dangerousSyncState;
    MXRoomMember *widgetCreatorRoomMember = [roomState.members memberWithUserId:widgetCreatorUserId];
    
    NSString *widgetDomain = @"";
    
    if (widget.url)
    {
        NSString *host = [[NSURL alloc] initWithString:widget.url].host;
        if (host)
        {
            widgetDomain = host;
        }
    }
    
    MXMediaManager *mediaManager = widget.mxSession.mediaManager;
    NSString *widgetCreatorDisplayName = widgetCreatorRoomMember.displayname;
    NSString *widgetCreatorAvatarURL = widgetCreatorRoomMember.avatarUrl;
    
    NSArray<NSString*> *permissionStrings = @[
                                              [VectorL10n roomWidgetPermissionDisplayNamePermission],
                                              [VectorL10n roomWidgetPermissionAvatarUrlPermission]
                                              ];
    
    WidgetPermissionViewModel *widgetPermissionViewModel = [[WidgetPermissionViewModel alloc] initWithCreatorUserId:widgetCreatorUserId
                                                                                                 creatorDisplayName:widgetCreatorDisplayName creatorAvatarUrl:widgetCreatorAvatarURL widgetDomain:widgetDomain
                                                                                                    isWebviewWidget:NO
                                                                                                  widgetPermissions:permissionStrings
                                                                                                       mediaManager:mediaManager];
    
    
    WidgetPermissionViewController *widgetPermissionViewController = [WidgetPermissionViewController instantiateWith:widgetPermissionViewModel];
    
    MXWeakify(self);
    
    widgetPermissionViewController.didTapContinueButton = ^{
        
        MXStrongifyAndReturnIfNil(self);
        
        [self.slidingModalPresenter dismissWithAnimated:YES completion:^{
            completion(YES);
        }];
    };
    
    widgetPermissionViewController.didTapCloseButton = ^{
        
        MXStrongifyAndReturnIfNil(self);
        
        [self.slidingModalPresenter dismissWithAnimated:YES completion:^{
            completion(NO);
        }];
    };
    
    [self.slidingModalPresenter present:widgetPermissionViewController
                                   from:self.presentedViewController
                               animated:YES
                             completion:nil];
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
                                       kMXEventTypeStringCallSelectAnswer,
                                       kMXEventTypeStringCallHangup,
                                       kMXEventTypeStringCallReject,
                                       kMXEventTypeStringCallNegotiate
                                       ]
                             onEvent:^(MXEvent *event, MXTimelineDirection direction, id customObject) {
                                 
                                 if (MXTimelineDirectionForwards == direction)
                                 {
                                     switch (event.eventType)
                                     {
                                         case MXEventTypeCallInvite:
                                         {
                                             if (self->noCallSupportAlert)
                                             {
                                                 [self->noCallSupportAlert dismissViewControllerAnimated:NO completion:nil];
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
                                             
                                             NSString *appDisplayName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
                                             
                                             NSString *message = [VectorL10n noVoip:callerDisplayname :appDisplayName];
                                             
                                             self->noCallSupportAlert = [UIAlertController alertControllerWithTitle:[VectorL10n noVoipTitle]
                                                                                                            message:message
                                                                                                     preferredStyle:UIAlertControllerStyleAlert];
                                             
                                             __weak typeof(self) weakSelf = self;
                                             
                                             [self->noCallSupportAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ignore]
                                                                                                          style:UIAlertActionStyleDefault
                                                                                                        handler:^(UIAlertAction * action) {
                                                                                                      
                                                                                                      if (weakSelf)
                                                                                                      {
                                                                                                          typeof(self) self = weakSelf;
                                                                                                          self->noCallSupportAlert = nil;
                                                                                                      }
                                                                                                      
                                                                                                  }]];
                                             
                                             [self->noCallSupportAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n rejectCall]
                                                                                                          style:UIAlertActionStyleDefault
                                                                                                        handler:^(UIAlertAction * action) {
                                                                                                      
                                                 // Reject the call by sending the hangup event
                                                 NSDictionary *content = @{
                                                     @"call_id": callInviteEventContent.callId,
                                                     @"version": kMXCallVersion,
                                                     @"party_id": mxSession.myDeviceId
                                                 };
                                                 
                                                 [mxSession.matrixRestClient sendEventToRoom:event.roomId threadId:nil eventType:kMXEventTypeStringCallReject content:content txnId:nil success:nil failure:^(NSError *error) {
                                                     MXLogDebug(@"[AppDelegate] enableNoVoIPOnMatrixSession: ERROR: Cannot send m.call.reject event.");
                                                 }];
                                                 
                                                 if (weakSelf)
                                                 {
                                                     typeof(self) self = weakSelf;
                                                     self->noCallSupportAlert = nil;
                                                 }
                                                 
                                             }]];
                                             
                                             [self showNotificationAlert:self->noCallSupportAlert];
                                             break;
                                         }
                                             
                                         case MXEventTypeCallAnswer:
                                         case MXEventTypeCallHangup:
                                         case MXEventTypeCallReject:
                                             // The call has ended. The alert is no more needed.
                                             if (self->noCallSupportAlert)
                                             {
                                                 [self->noCallSupportAlert dismissViewControllerAnimated:YES completion:nil];
                                                 self->noCallSupportAlert = nil;
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


#pragma mark - Cross-signing

- (void)checkCrossSigningForSession:(MXSession*)mxSession
{
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive)
    {
        MXLogDebug(@"[AppDelegate] checkCrossSigningForSession called while the app is not active. Ignore it.");
        return;
    }
    
    if (mxSession.crypto.crossSigning)
    {
        // Get the up-to-date cross-signing state
        MXWeakify(self);
        [mxSession.crypto.crossSigning refreshStateWithSuccess:^(BOOL stateUpdated) {
            MXStrongifyAndReturnIfNil(self);
            
            MXLogDebug(@"[AppDelegate] handleAppState: crossSigning.state: %@", @(mxSession.crypto.crossSigning.state));
            
            switch (mxSession.crypto.crossSigning.state)
            {
                case MXCrossSigningStateCrossSigningExists:
                    MXLogDebug(@"[AppDelegate] handleAppState: presentVerifyCurrentSessionAlertIfNeededWithSession");
                    [self.masterTabBarController presentVerifyCurrentSessionAlertIfNeededWithSession:mxSession];
                    break;
                case MXCrossSigningStateCanCrossSign:
                    MXLogDebug(@"[AppDelegate] handleAppState: presentReviewUnverifiedSessionsAlertIfNeededWithSession");
                    [self.masterTabBarController presentReviewUnverifiedSessionsAlertIfNeededWithSession:mxSession];
                    break;
                default:
                    break;
            }
        } failure:^(NSError * _Nonnull error) {
            MXLogDebug(@"[AppDelegate] handleAppState: crossSigning.state: %@. Error: %@", @(mxSession.crypto.crossSigning.state), error);
        }];
    }
}


#pragma mark - Incoming room key requests handling

- (void)enableRoomKeyRequestObserver:(MXSession*)mxSession
{
    roomKeyRequestObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:kMXCryptoRoomKeyRequestNotification
                                                      object:mxSession.crypto
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *notif)
     {
         [self checkPendingRoomKeyRequestsInSession:mxSession];
     }];

    roomKeyRequestCancellationObserver  =
    [[NSNotificationCenter defaultCenter] addObserverForName:kMXCryptoRoomKeyRequestCancellationNotification
                                                      object:mxSession.crypto
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *notif)
     {
         [self checkPendingRoomKeyRequestsInSession:mxSession];
     }];
}

- (void)disableRoomKeyRequestObserver:(MXSession*)mxSession
{
    if (roomKeyRequestObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:roomKeyRequestObserver];
        roomKeyRequestObserver = nil;
    }

    if (roomKeyRequestCancellationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:roomKeyRequestCancellationObserver];
        roomKeyRequestCancellationObserver = nil;
    }
}

// Check if a key share dialog must be displayed for the given session
- (void)checkPendingRoomKeyRequestsInSession:(MXSession*)mxSession
{
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive)
    {
        MXLogDebug(@"[AppDelegate] checkPendingRoomKeyRequestsInSession called while the app is not active. Ignore it.");
        return;
    }
    
    if (![mxSession.crypto isKindOfClass:[MXLegacyCrypto class]])
    {
        MXLogDebug(@"[AppDelegate] checkPendingRoomKeyRequestsInSession: Only legacy crypto allows manually accepting/rejecting key requests");
        return;
    }
    MXLegacyCrypto *crypto = (MXLegacyCrypto *)mxSession.crypto;

    MXWeakify(self);
    [crypto pendingKeyRequests:^(MXUsersDevicesMap<NSArray<MXIncomingRoomKeyRequest *> *> *pendingKeyRequests) {
        
        MXStrongifyAndReturnIfNil(self);
        MXLogDebug(@"[AppDelegate] checkPendingRoomKeyRequestsInSession: cross-signing state: %ld, pendingKeyRequests.count: %@. Already displayed: %@",
                   crypto.crossSigning.state,
                   @(pendingKeyRequests.count),
                   self->roomKeyRequestViewController ? @"YES" : @"NO");

        if (!crypto.crossSigning || crypto.crossSigning.state == MXCrossSigningStateNotBootstrapped)
        {
            if (self->roomKeyRequestViewController)
            {
                // Check if the current RoomKeyRequestViewController is still valid
                MXSession *currentMXSession = self->roomKeyRequestViewController.mxSession;
                NSString *currentUser = self->roomKeyRequestViewController.device.userId;
                NSString *currentDevice = self->roomKeyRequestViewController.device.deviceId;

                NSArray<MXIncomingRoomKeyRequest *> *currentPendingRequest = [pendingKeyRequests objectForDevice:currentDevice forUser:currentUser];

                if (currentMXSession == mxSession && currentPendingRequest.count == 0)
                {
                    MXLogDebug(@"[AppDelegate] checkPendingRoomKeyRequestsInSession: Cancel current dialog");

                    // The key request has been probably cancelled, remove the popup
                    [self->roomKeyRequestViewController hide];
                    self->roomKeyRequestViewController = nil;
                }
            }
        }

        if (!self->roomKeyRequestViewController && pendingKeyRequests.count)
        {
            // Pick the first coming user/device pair
            NSString *userId = pendingKeyRequests.userIds.firstObject;
            NSString *deviceId = [pendingKeyRequests deviceIdsForUser:userId].firstObject;
            
            // Give the client a chance to refresh the device list
            MXWeakify(self);
            [crypto downloadKeys:@[userId] forceDownload:NO success:^(MXUsersDevicesMap<MXDeviceInfo *> *usersDevicesInfoMap, NSDictionary<NSString *,MXCrossSigningInfo *> *crossSigningKeysMap) {
                
                MXStrongifyAndReturnIfNil(self);
                MXDeviceInfo *deviceInfo = [usersDevicesInfoMap objectForDevice:deviceId forUser:userId];
                if (deviceInfo)
                {
                    if (!crypto.crossSigning || crypto.crossSigning.state == MXCrossSigningStateNotBootstrapped)
                    {
                        BOOL wasNewDevice = (deviceInfo.trustLevel.localVerificationStatus == MXDeviceUnknown);
                        
                        void (^openDialog)(void) = ^void()
                        {
                            MXLogDebug(@"[AppDelegate] checkPendingRoomKeyRequestsInSession: Open dialog for %@", deviceInfo);

                            self->roomKeyRequestViewController = [[RoomKeyRequestViewController alloc] initWithDeviceInfo:deviceInfo wasNewDevice:wasNewDevice andMatrixSession:mxSession crypto:crypto onComplete:^{

                                self->roomKeyRequestViewController = nil;

                                // Check next pending key request, if any
                                [self checkPendingRoomKeyRequests];
                            }];

                            [self->roomKeyRequestViewController show];
                        };

                        // If the device was new before, it's not any more.
                        if (wasNewDevice)
                        {
                            [crypto setDeviceVerification:MXDeviceUnverified forDevice:deviceId ofUser:userId success:openDialog failure:nil];
                        }
                        else
                        {
                            openDialog();
                        }
                    }
                    else if (deviceInfo.trustLevel.isVerified)
                    {
                        [crypto acceptAllPendingKeyRequestsFromUser:userId andDevice:deviceId onComplete:^{
                            [self checkPendingRoomKeyRequests];
                        }];
                    }
                    else
                    {
                        [crypto ignoreAllPendingKeyRequestsFromUser:userId andDevice:deviceId onComplete:^{
                            [self checkPendingRoomKeyRequests];
                        }];
                    }
                }
                else
                {
                    MXLogDebug(@"[AppDelegate] checkPendingRoomKeyRequestsInSession: No details found for device %@:%@", userId, deviceId);
                    [crypto ignoreAllPendingKeyRequestsFromUser:userId andDevice:deviceId onComplete:^{
                        [self checkPendingRoomKeyRequests];
                    }];
                }
            } failure:^(NSError *error) {
                // Retry later
                MXLogDebug(@"[AppDelegate] checkPendingRoomKeyRequestsInSession: Failed to download device keys. Retry");
                [self checkPendingRoomKeyRequests];
            }];
        }
    }];
}

// Check all opened MXSessions for key share dialog 
- (void)checkPendingRoomKeyRequests
{
    for (MXSession *mxSession in mxSessionArray)
    {
        [self checkPendingRoomKeyRequestsInSession:mxSession];
    }
}

#pragma mark - Incoming key verification handling

- (void)enableIncomingKeyVerificationObserver:(MXSession*)mxSession
{
    incomingKeyVerificationObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:MXKeyVerificationManagerNewTransactionNotification
                                                      object:mxSession.crypto.keyVerificationManager
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *notif)
     {
         NSObject *object = notif.userInfo[MXKeyVerificationManagerNotificationTransactionKey];
         if ([object conformsToProtocol:@protocol(MXSASTransaction)] && ((id<MXSASTransaction>)object).isIncoming)
         {
             [self checkPendingIncomingKeyVerificationsInSession:mxSession];
         }
     }];
}

- (void)disableIncomingKeyVerificationObserver:(MXSession*)mxSession
{
    if (incomingKeyVerificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:incomingKeyVerificationObserver];
        incomingKeyVerificationObserver = nil;
    }
}

// Check if an incoming key verification dialog must be displayed for the given session
- (void)checkPendingIncomingKeyVerificationsInSession:(MXSession*)mxSession
{
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive)
    {
        MXLogDebug(@"[AppDelegate][MXKeyVerification] checkPendingIncomingKeyVerificationsInSession: called while the app is not active. Ignore it.");
        return;
    }

    [mxSession.crypto.keyVerificationManager transactions:^(NSArray<id<MXKeyVerificationTransaction>> * _Nonnull transactions) {

        MXLogDebug(@"[AppDelegate][MXKeyVerification] checkPendingIncomingKeyVerificationsInSession: transactions: %@", transactions);

        for (id<MXKeyVerificationTransaction> transaction in transactions)
        {
            if ([transaction conformsToProtocol:@protocol(MXSASTransaction)] && transaction.isIncoming)
            {
                id<MXSASTransaction> incomingTransaction = (id<MXSASTransaction>)transaction;
                if (incomingTransaction.state == MXSASTransactionStateIncomingShowAccept)
                {
                    [self presentIncomingKeyVerification:incomingTransaction inSession:mxSession];
                    break;
                }
            }
        }
    }];
}

// Check all opened MXSessions for incoming key verification dialog
- (void)checkPendingIncomingKeyVerifications
{
    for (MXSession *mxSession in mxSessionArray)
    {
        [self checkPendingIncomingKeyVerificationsInSession:mxSession];
    }
}

- (BOOL)presentIncomingKeyVerificationRequest:(id<MXKeyVerificationRequest>)incomingKeyVerificationRequest
                                    inSession:(MXSession*)session
{
    BOOL presented = NO;
    
    if (!keyVerificationCoordinatorBridgePresenter.isPresenting)
    {
        MXLogDebug(@"[AppDelegate] presentIncomingKeyVerificationRequest");
        
        keyVerificationCoordinatorBridgePresenter = [[KeyVerificationCoordinatorBridgePresenter alloc] initWithSession:session];
        keyVerificationCoordinatorBridgePresenter.delegate = self;
        
        [keyVerificationCoordinatorBridgePresenter presentFrom:self.presentedViewController incomingKeyVerificationRequest:incomingKeyVerificationRequest animated:YES];
        
        presented = YES;
    }
    else
    {
        MXLogDebug(@"[AppDelegate][MXKeyVerification] presentIncomingKeyVerificationRequest: Controller already presented.");
    }
    
    return presented;
}

- (BOOL)presentIncomingKeyVerification:(id<MXSASTransaction>)transaction inSession:(MXSession*)mxSession
{
    MXLogDebug(@"[AppDelegate][MXKeyVerification] presentIncomingKeyVerification: %@", transaction);

    BOOL presented = NO;
    if (!keyVerificationCoordinatorBridgePresenter.isPresenting)
    {
        keyVerificationCoordinatorBridgePresenter = [[KeyVerificationCoordinatorBridgePresenter alloc] initWithSession:mxSession];
        keyVerificationCoordinatorBridgePresenter.delegate = self;

        [keyVerificationCoordinatorBridgePresenter presentFrom:self.presentedViewController incomingTransaction:transaction animated:YES];

        presented = YES;
    }
    else
    {
        MXLogDebug(@"[AppDelegate][MXKeyVerification] presentIncomingKeyVerification: Controller already presented.");
    }
    return presented;
}

- (BOOL)presentUserVerificationForRoomMember:(MXRoomMember*)roomMember
                                     session:(MXSession*)mxSession
                                  completion:(void (^)(void))completion;
{
    MXLogDebug(@"[AppDelegate][MXKeyVerification] presentUserVerificationForRoomMember: %@", roomMember);
    
    BOOL presented = NO;
    if (!keyVerificationCoordinatorBridgePresenter.isPresenting)
    {
        keyVerificationCoordinatorBridgePresenter = [[KeyVerificationCoordinatorBridgePresenter alloc] initWithSession:mxSession];
        keyVerificationCoordinatorBridgePresenter.delegate = self;
        
        [keyVerificationCoordinatorBridgePresenter presentFrom:self.presentedViewController roomMember:roomMember animated:YES];
        
        presented = YES;
        
        keyVerificationCompletionBlock = completion;
    }
    else
    {
        MXLogDebug(@"[AppDelegate][MXKeyVerification] presentUserVerificationForRoomMember: Controller already presented.");
    }
    return presented;
}

- (BOOL)presentSelfVerificationForOtherDeviceId:(NSString*)deviceId inSession:(MXSession*)mxSession
{
    MXLogDebug(@"[AppDelegate][MXKeyVerification] presentSelfVerificationForOtherDeviceId: %@", deviceId);
    
    BOOL presented = NO;
    if (!keyVerificationCoordinatorBridgePresenter.isPresenting)
    {
        keyVerificationCoordinatorBridgePresenter = [[KeyVerificationCoordinatorBridgePresenter alloc] initWithSession:mxSession];
        keyVerificationCoordinatorBridgePresenter.delegate = self;
        
        [keyVerificationCoordinatorBridgePresenter presentFrom:self.presentedViewController otherUserId:mxSession.myUser.userId otherDeviceId:deviceId animated:YES];
        
        presented = YES;
    }
    else
    {
        MXLogDebug(@"[AppDelegate][MXKeyVerification] presentUserVerificationForRoomMember: Controller already presented.");
    }
    return presented;
}

- (void)keyVerificationCoordinatorBridgePresenterDelegateDidComplete:(KeyVerificationCoordinatorBridgePresenter *)coordinatorBridgePresenter otherUserId:(NSString * _Nonnull)otherUserId otherDeviceId:(NSString * _Nonnull)otherDeviceId
{
    id<MXCrypto> crypto = coordinatorBridgePresenter.session.crypto;
    if ([crypto isKindOfClass:[MXLegacyCrypto class]] && (!crypto.backup.hasPrivateKeyInCryptoStore || !crypto.backup.enabled))
    {
        MXLogDebug(@"[AppDelegate][MXKeyVerification] requestAllPrivateKeys: Request key backup private keys");
        [(MXLegacyCrypto *)crypto setOutgoingKeyRequestsEnabled:YES onComplete:nil];
    }
    [self dismissKeyVerificationCoordinatorBridgePresenter];
}

- (void)keyVerificationCoordinatorBridgePresenterDelegateDidCancel:(KeyVerificationCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter
{
    [self dismissKeyVerificationCoordinatorBridgePresenter];
}

- (void)dismissKeyVerificationCoordinatorBridgePresenter
{
    [keyVerificationCoordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        [self checkPendingIncomingKeyVerifications];
    }];
    
    keyVerificationCoordinatorBridgePresenter = nil;
    
    if (keyVerificationCompletionBlock) {
        keyVerificationCompletionBlock();
    }
    keyVerificationCompletionBlock = nil;
}

#pragma mark - New request

- (void)registerNewRequestNotificationForSession:(MXSession*)session
{
    id<MXKeyVerificationManager> keyVerificationManager = session.crypto.keyVerificationManager;
    
    if (!keyVerificationManager)
    {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyVerificationNewRequestNotification:) name:MXKeyVerificationManagerNewRequestNotification object:keyVerificationManager];
}

- (void)keyVerificationNewRequestNotification:(NSNotification *)notification
{
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)
    {
        return;
    }
    
    if (_masterTabBarController.isOnboardingInProgress)
    {
        MXLogDebug(@"[AppDelegate][KeyVerification] keyVerificationNewRequestNotification: Postpone requests during the authentication process");
        
        // 10s is quite arbitrary
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self keyVerificationNewRequestNotification:notification];
        });
        return;
    }
    
    NSDictionary *userInfo = notification.userInfo;
    
    id<MXKeyVerificationRequest> keyVerificationRequest = userInfo[MXKeyVerificationManagerNotificationRequestKey];
    
    if (keyVerificationRequest.transport == MXKeyVerificationTransportDirectMessage)
    {
        if (!keyVerificationRequest.isFromMyUser && keyVerificationRequest.state == MXKeyVerificationRequestStatePending)
        {
            MXKAccount *currentAccount = [MXKAccountManager sharedManager].activeAccounts.firstObject;
            MXSession *session = currentAccount.mxSession;
            MXRoom *room = [currentAccount.mxSession roomWithRoomId:keyVerificationRequest.roomId];
            if (!room)
            {
                MXLogDebug(@"[AppDelegate][KeyVerification] keyVerificationRequestDidChangeNotification: Unknown room");
                return;
            }
            
            NSString *sender = keyVerificationRequest.otherUser;

            [room state:^(MXRoomState *roomState) {

                NSString *senderName = [roomState.members memberName:sender];
                
                [self presentNewKeyVerificationRequestAlertForSession:session senderName:senderName senderId:sender request:keyVerificationRequest];
            }];
        }
    }
    else if (keyVerificationRequest.transport == MXKeyVerificationTransportToDevice)
    {
        
        if (!keyVerificationRequest.isFromMyDevice
            && keyVerificationRequest.state == MXKeyVerificationRequestStatePending)
        {
            if (keyVerificationRequest.isFromMyUser)
            {
                // Self verification
                MXLogDebug(@"[AppDelegate][KeyVerification] keyVerificationNewRequestNotification: Self verification from %@", keyVerificationRequest.otherDevice);
                
                if (!self.handleSelfVerificationRequest)
                {
                    MXLogDebug(@"[AppDelegate][KeyVerification] keyVerificationNewRequestNotification: Self verification handled elsewhere");
                    return;
                }
                      
                NSString *myUserId = keyVerificationRequest.otherUser;
                MXKAccount *account = [[MXKAccountManager sharedManager] accountForUserId:myUserId];
                if (account)
                {
                    MXSession *session = account.mxSession;
                    MXUser *user = [session userWithUserId:myUserId];
                    
                    [self presentNewKeyVerificationRequestAlertForSession:session senderName:user.displayname senderId:user.userId request:keyVerificationRequest];
                }
            }
            else
            {
                // Device verification from other user
                // This happens when they or our user do not have cross-signing enabled
                MXLogDebug(@"[AppDelegate][KeyVerification] keyVerificationNewRequestNotification: Device verification from other user %@:%@", keyVerificationRequest.otherUser, keyVerificationRequest.otherDevice);
                
                NSString *myUserId = keyVerificationRequest.myUserId;
                NSString *userId = keyVerificationRequest.otherUser;
                MXKAccount *account = [[MXKAccountManager sharedManager] accountForUserId:myUserId];
                if (account)
                {
                    MXSession *session = account.mxSession;
                    MXUser *user = [session userWithUserId:userId];
                    
                    [self presentNewKeyVerificationRequestAlertForSession:session senderName:user.displayname senderId:user.userId request:keyVerificationRequest];
                }
                else
                {
                    NSDictionary *details = @{
                        @"request_id": keyVerificationRequest.requestId ?: @"unknown"
                    };
                    MXLogErrorDetails(@"[AppDelegate][KeyVerification] keyVerificationNewRequestNotification: No account available", details);
                }
            }
        }
        else
        {
            MXLogDebug(@"[AppDelegate][KeyVerification] keyVerificationNewRequestNotification. Bad request state: %@", keyVerificationRequest);
        }
    }
}

- (void)presentNewKeyVerificationRequestAlertForSession:(MXSession*)session
                                             senderName:(NSString*)senderName
                                               senderId:(NSString*)senderId
                                                request:(id<MXKeyVerificationRequest>)keyVerificationRequest
{
    if (keyVerificationRequest.state != MXKeyVerificationRequestStatePending)
    {
        MXLogDebug(@"[AppDelegate] presentNewKeyVerificationRequest: Request already accepted. Do not display it");
        return;
    }
    
    if (self.incomingKeyVerificationRequestAlertController)
    {
        [self.incomingKeyVerificationRequestAlertController dismissViewControllerAnimated:NO completion:nil];
    }
    
    if (self.userNewSignInAlertController
        && [session.myUserId isEqualToString:senderId])
    {
        // If it is a self verification for my device, we can discard the new signin alert.
        // Note: It will not work well with several devices to verify at the same time.
        MXLogDebug(@"[AppDelegate] presentNewKeyVerificationRequest: Remove the alert for new sign in detected");
        [self.userNewSignInAlertController dismissViewControllerAnimated:NO completion:^{
            self.userNewSignInAlertController = nil;
            [self presentNewKeyVerificationRequestAlertForSession:session senderName:senderName senderId:senderId request:keyVerificationRequest];
        }];
    }
    
    NSString *senderInfo;
    
    if (senderName)
    {
        senderInfo = [NSString stringWithFormat:@"%@ (%@)", senderName, senderId];
    }
    else
    {
        senderInfo = senderId;
    }
    
    
    __block id observer;
    void (^removeObserver)(void) = ^() {
        if (observer)
        {
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
            observer = nil;
        }
    };
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[VectorL10n keyVerificationTileRequestIncomingTitle]
                                                                             message:senderInfo
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:[VectorL10n keyVerificationTileRequestIncomingApprovalAccept]
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
        removeObserver();
        [self presentIncomingKeyVerificationRequest:keyVerificationRequest inSession:session];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:[VectorL10n keyVerificationTileRequestIncomingApprovalDecline]
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction * action) {
        removeObserver();
        [keyVerificationRequest cancelWithCancelCode:MXTransactionCancelCode.user success:^{
            
        } failure:^(NSError * _Nonnull error) {
            MXLogDebug(@"[AppDelegate][KeyVerification] Fail to cancel incoming key verification request with error: %@", error);
        }];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:[VectorL10n later]
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction * action) {
        removeObserver();
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
    self.incomingKeyVerificationRequestAlertController = alertController;
    
    observer = [[NSNotificationCenter defaultCenter] addObserverForName:MXKeyVerificationRequestDidChangeNotification
                                                                 object:keyVerificationRequest
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(NSNotification *note) {
        if (keyVerificationRequest.state != MXKeyVerificationRequestStatePending)
        {
            if (self.incomingKeyVerificationRequestAlertController == alertController)
            {
                [self.incomingKeyVerificationRequestAlertController dismissViewControllerAnimated:NO completion:nil];
                removeObserver();
            }
        }
    }];
}

#pragma mark - New Sign In

- (void)registerUserDidSignInOnNewDeviceNotificationForSession:(MXSession*)session
{
    id<MXCrossSigning> crossSigning = session.crypto.crossSigning;
    
    if (!crossSigning)
    {
        return;
    }
    
    self.userDidSignInOnNewDeviceObserver = [NSNotificationCenter.defaultCenter addObserverForName:MXCrossSigningMyUserDidSignInOnNewDeviceNotification
                                                    object:crossSigning
                                                     queue:[NSOperationQueue mainQueue]
                                                usingBlock:^(NSNotification *notification)
     {
         NSArray<NSString*> *deviceIds = notification.userInfo[MXCrossSigningNotificationDeviceIdsKey];
         
         [session.matrixRestClient devices:^(NSArray<MXDevice *> *devices) {
             
             NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.deviceId IN %@", deviceIds];
             NSArray<MXDevice*> *newDevices = [devices filteredArrayUsingPredicate:predicate];
             
             NSArray *sortedDevices = [newDevices sortedArrayUsingComparator:^NSComparisonResult(MXDevice * _Nonnull device1, MXDevice *  _Nonnull device2) {
                 
                 if (device1.lastSeenTs == device2.lastSeenTs)
                 {
                     return NSOrderedSame;
                 }
                 
                 return device1.lastSeenTs > device2.lastSeenTs ? NSOrderedDescending : NSOrderedAscending;
             }];
             
             MXDevice *mostRecentDevice = sortedDevices.lastObject;
             
             if (mostRecentDevice)
             {
                 [self presentNewSignInAlertForDevice:mostRecentDevice inSession:session];
             }
             
         } failure:^(NSError *error) {
             MXLogDebug(@"[AppDelegate][NewSignIn] Fail to fetch devices");
         }];
     }];
}

- (void)presentNewSignInAlertForDevice:(MXDevice*)device inSession:(MXSession*)session
{
    MXLogDebug(@"[AppDelegate] presentNewSignInAlertForDevice: %@", device.deviceId);
    
    if (self.userNewSignInAlertController)
    {
        [self.userNewSignInAlertController dismissViewControllerAnimated:NO completion:nil];
    }
    
    NSString *deviceInfo;
    
    if (device.displayName)
    {
        deviceInfo = [NSString stringWithFormat:@"%@ (%@)", device.displayName, device.deviceId];
    }
    else
    {
        deviceInfo = device.deviceId;
    }
    
    NSString *alertMessage = [VectorL10n deviceVerificationSelfVerifyAlertMessage:deviceInfo];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[VectorL10n deviceVerificationSelfVerifyAlertTitle]
                                                                   message:alertMessage
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n deviceVerificationSelfVerifyAlertValidateAction]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
        self.userNewSignInAlertController = nil;
        [self presentSelfVerificationForOtherDeviceId:device.deviceId inSession:session];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n later]
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * action) {
        self.userNewSignInAlertController = nil;
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    self.userNewSignInAlertController = alert;
}


#pragma mark - Cross-signing reset detection

- (void)registerDidChangeCrossSigningKeysNotificationForSession:(MXSession*)session
{
    id<MXCrossSigning> crossSigning = session.crypto.crossSigning;
    
    if (!crossSigning)
    {
        return;
    }
    
    MXWeakify(self);

    self.userDidChangeCrossSigningKeysObserver = [NSNotificationCenter.defaultCenter addObserverForName:MXCrossSigningDidChangeCrossSigningKeysNotification
                                                                                                 object:crossSigning
                                                                                                  queue:[NSOperationQueue mainQueue]
                                                                                             usingBlock:^(NSNotification *notification)
                                                  {
                                                  
         MXStrongifyAndReturnIfNil(self);
               
        MXLogDebug(@"[AppDelegate] registerDidChangeCrossSigningKeysNotificationForSession");
        
        if (self.userNewSignInAlertController)
        {
            MXLogDebug(@"[AppDelegate] registerDidChangeCrossSigningKeysNotificationForSession: Hide NewSignInAlertController");
            
            [self.userNewSignInAlertController dismissViewControllerAnimated:NO completion:^{
                [self.masterTabBarController presentVerifyCurrentSessionAlertIfNeededWithSession:session];
            }];
            self.userNewSignInAlertController = nil;
        }
        else
        {
            [self.masterTabBarController presentVerifyCurrentSessionAlertIfNeededWithSession:session];
        }
    }];
}


#pragma mark - Complete security

- (BOOL)presentCompleteSecurityForSession:(MXSession*)mxSession
{
    MXLogDebug(@"[AppDelegate][MXKeyVerification] presentCompleteSecurityForSession");
    
    BOOL presented = NO;
    if (!keyVerificationCoordinatorBridgePresenter.isPresenting)
    {
        keyVerificationCoordinatorBridgePresenter = [[KeyVerificationCoordinatorBridgePresenter alloc] initWithSession:mxSession];
        keyVerificationCoordinatorBridgePresenter.cancellable = !mxSession.vc_homeserverConfiguration.encryption.isSecureBackupRequired;
        keyVerificationCoordinatorBridgePresenter.delegate = self;
        
        [keyVerificationCoordinatorBridgePresenter presentCompleteSecurityFrom:self.presentedViewController isNewSignIn:NO animated:YES];
        
        presented = YES;
    }
    else
    {
        MXLogDebug(@"[AppDelegate][MXKeyVerification] presentCompleteSecurityForSession: Controller already presented.");
    }
    return presented;
}

#pragma mark - GDPR consent

// Observe user GDPR consent not given
- (void)registerUserConsentNotGivenNotification
{
    [NSNotificationCenter.defaultCenter addObserverForName:kMXHTTPClientUserConsentNotGivenErrorNotification
                                                    object:nil
                                                     queue:[NSOperationQueue mainQueue]
                                                usingBlock:^(NSNotification *notification)
    {
        NSString *consentURI = notification.userInfo[kMXHTTPClientUserConsentNotGivenErrorNotificationConsentURIKey];
        if (consentURI
            && self.gdprConsentNotGivenAlertController.presentingViewController == nil
            && self.gdprConsentController.presentingViewController == nil)
        {
            self.gdprConsentNotGivenAlertController = nil;
            self.gdprConsentController = nil;
            
            __weak typeof(self) weakSelf = self;
            
            MXSession *mainSession = self.mxSessions.firstObject;
            NSString *homeServerName = mainSession.matrixRestClient.credentials.homeServerName;
            
            NSString *alertMessage = [VectorL10n gdprConsentNotGivenAlertMessage:homeServerName];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:[VectorL10n settingsTermConditions]
                                                                           message:alertMessage
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n gdprConsentNotGivenAlertReviewNowAction]
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action) {
                                                        
                                                        typeof(weakSelf) strongSelf = weakSelf;
                                                        
                                                        if (strongSelf)
                                                        {
                                                            [strongSelf presentGDPRConsentFromViewController:self.presentedViewController consentURI:consentURI];
                                                        }
                                                    }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n later]
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
            
            self.gdprConsentNotGivenAlertController = alert;
        }
    }];
}

- (void)presentGDPRConsentFromViewController:(UIViewController*)viewController consentURI:(NSString*)consentURI
{
    GDPRConsentViewController *gdprConsentViewController = [[GDPRConsentViewController alloc] initWithURL:consentURI];    
    
    UIBarButtonItem *closeBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[VectorL10n close]
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(dismissGDPRConsent)];
    
    gdprConsentViewController.navigationItem.leftBarButtonItem = closeBarButtonItem;
    
    UINavigationController *navigationController = [[RiotNavigationController alloc] initWithRootViewController:gdprConsentViewController];
    
    [viewController presentViewController:navigationController animated:YES completion:nil];
    
    self.gdprConsentController = navigationController;
    
    gdprConsentViewController.delegate = self;
}

- (void)dismissGDPRConsent
{    
    [self.gdprConsentController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - GDPRConsentViewControllerDelegate

- (void)gdprConsentViewControllerDidConsentToGDPRWithSuccess:(GDPRConsentViewController *)gdprConsentViewController
{
    MXSession *session = mxSessionArray.firstObject;

    // Leave the GDPR consent right now
    [self dismissGDPRConsent];
        
    BOOL botCreationEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"enableBotCreation"];

    if (botCreationEnabled)
    {
        // And create the room with riot bot in //
        self.onBoardingManager = [[OnBoardingManager alloc] initWithSession:session];
        
        MXWeakify(self);
        void (^createRiotBotDMcompletion)(void) = ^() {
            MXStrongifyAndReturnIfNil(self);

            self.onBoardingManager = nil;
        };
        
        [self.onBoardingManager createRiotBotDirectMessageIfNeededWithSuccess:^{
            createRiotBotDMcompletion();
        } failure:^(NSError * _Nonnull error) {
            createRiotBotDMcompletion();
        }];
    }
}

#pragma mark - Settings

- (void)setupUserDefaults
{
    // Register MatrixKit defaults.
    NSDictionary *defaults = @{
        @"enableBotCreation": @(BuildSettings.enableBotCreation),
        @"maxAllowedMediaCacheSize": @(BuildSettings.maxAllowedMediaCacheSize),
        @"presenceColorForOfflineUser": @(BuildSettings.presenceColorForOfflineUser),
        @"presenceColorForOnlineUser": @(BuildSettings.presenceColorForOnlineUser),
        @"presenceColorForUnavailableUser": @(BuildSettings.presenceColorForUnavailableUser),
        @"showAllEventsInRoomHistory": @(BuildSettings.showAllEventsInRoomHistory),
        @"showLeftMembersInRoomMemberList": @(BuildSettings.showLeftMembersInRoomMemberList),
        @"showRedactionsInRoomHistory": @(BuildSettings.showRedactionsInRoomHistory),
        @"showUnsupportedEventsInRoomHistory": @(BuildSettings.showUnsupportedEventsInRoomHistory),
        @"sortRoomMembersUsingLastSeenTime": @(BuildSettings.syncLocalContacts),
        @"syncLocalContacts": @(BuildSettings.syncLocalContacts),
        @"pushKitAppIdProd": BuildSettings.pushKitAppIdProd,
        @"pushKitAppIdDev": BuildSettings.pushKitAppIdDev,
        @"pusherAppIdProd": BuildSettings.pusherAppIdProd,
        @"pusherAppIdDev": BuildSettings.pusherAppIdDev
    };
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    // Migrates old UserDefaults values if showDecryptedContentInNotifications hasn't been set
    if (!RiotSettings.shared.isUserDefaultsMigrated)
    {
        [RiotSettings.shared migrate];
    }
    
    // Show encrypted message notification content by default.
    if (!RiotSettings.shared.isShowDecryptedContentInNotificationsHasBeenSetOnce)
    {
        RiotSettings.shared.showDecryptedContentInNotifications = BuildSettings.decryptNotificationsByDefault;
    }
    
    // Need to set `showAllRoomsInHomeSpace` to `true` for the new App Layout
    if (BuildSettings.newAppLayoutEnabled)
    {
        RiotSettings.shared.showAllRoomsInHomeSpace = YES;
    }
    
    if (RiotSettings.shared.forceThreadsEnabled)
    {
        RiotSettings.shared.enableThreads = YES;
        RiotSettings.shared.forceThreadsEnabled = NO;
    }
}

#pragma mark - App version management

- (void)checkAppVersion
{
    // Check if we should display a major update alert
    [self checkMajorUpdate];
    
    // Update the last app version used
    [AppVersion updateLastUsedVersion];
}

- (void)checkMajorUpdate
{
    if (self.majorUpdateManager.shouldShowMajorUpdate)
    {
        // When you do not understand why the UI does not work as expected...
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showMajorUpdate];
        });
    }
}

- (void)showMajorUpdate
{
    if (!self.slidingModalPresenter)
    {
        self.slidingModalPresenter = [SlidingModalPresenter new];
    }
    
    [self.slidingModalPresenter dismissWithAnimated:NO completion:nil];
    
    MajorUpdateViewController *majorUpdateViewController = [MajorUpdateViewController instantiate];
    
    MXWeakify(self);
    
    majorUpdateViewController.didTapLearnMoreButton = ^{
        
        MXStrongifyAndReturnIfNil(self);
        
        [[UIApplication sharedApplication] vc_open:self.majorUpdateManager.learnMoreURL completionHandler:^(BOOL success) {
            if (!success)
            {
                [self showAlertWithTitle:[VectorL10n error] message:[VectorL10n roomMessageUnableOpenLinkErrorMessage]];
            }
        }];
        
        [self.slidingModalPresenter dismissWithAnimated:YES completion:^{
        }];
    };
    
    majorUpdateViewController.didTapDoneButton = ^{
        
        MXStrongifyAndReturnIfNil(self);
        
        [self.slidingModalPresenter dismissWithAnimated:YES completion:^{
        }];
    };
    
    [self.slidingModalPresenter present:majorUpdateViewController
                                   from:self.presentedViewController
                               animated:YES
                             completion:nil];
}

#pragma mark - SetPinCoordinatorBridgePresenterDelegate

- (void)setPinCoordinatorBridgePresenterDelegateDidComplete:(SetPinCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithMainAppWindow:self.window];
    self.setPinCoordinatorBridgePresenter = nil;
    [self afterAppUnlockedByPin:[UIApplication sharedApplication]];
}

- (void)setPinCoordinatorBridgePresenterDelegateDidCompleteWithReset:(SetPinCoordinatorBridgePresenter *)coordinatorBridgePresenter dueToTooManyErrors:(BOOL)dueToTooManyErrors
{
    if (dueToTooManyErrors)
    {
        [coordinatorBridgePresenter dismissWithMainAppWindow:self.window];
        self.setPinCoordinatorBridgePresenter = nil;
        [self logoutWithConfirmation:NO completion:^(BOOL isLoggedOut) {
            if (isLoggedOut)
            {
                [self showAlertWithTitle:nil message:[VectorL10n pinProtectionKickUserAlertMessage]];
            }
        }];
    }
    else
    {
        [coordinatorBridgePresenter dismissWithMainAppWindow:self.window];
        self.setPinCoordinatorBridgePresenter = nil;
        [self logoutWithConfirmation:NO completion:nil];
    }
}

#pragma mark - CallPresenterDelegate

- (void)callPresenter:(CallPresenter *)presenter presentCallViewController:(CallViewController *)viewController completion:(void (^)(void))completion
{
    if (@available(iOS 13.0, *))
    {
        viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    
    [self presentViewController:viewController animated:NO completion:completion];
}

- (void)callPresenter:(CallPresenter *)presenter dismissCallViewController:(UIViewController *)viewController completion:(void (^)(void))completion
{
    // Check whether the call view controller is actually presented
    if (viewController.presentingViewController)
    {
        [viewController.presentingViewController dismissViewControllerAnimated:NO completion:^{
            
            if ([viewController isKindOfClass:CallViewController.class])
            {
                CallViewController *callVC = (CallViewController *)viewController;
                if (callVC.shouldPromptForStunServerFallback)
                {
                    [self promptForStunServerFallback];
                }
            }
            
            if (completion)
            {
                completion();
            }
            
        }];
    }
    else
    {
        if (completion)
        {
            completion();
        }
    }
}

- (void)callPresenter:(CallPresenter *)presenter enterPipForCallViewController:(UIViewController *)viewController completion:(void (^)(void))completion
{
    // Check whether the call view controller is actually presented
    if (viewController.presentingViewController)
    {
        [viewController dismissViewControllerAnimated:YES completion:completion];
    }
    else
    {
        if (completion)
        {
            completion();
        }
    }
}

- (void)callPresenter:(CallPresenter *)presenter exitPipForCallViewController:(UIViewController *)viewController completion:(void (^)(void))completion
{
    if (@available(iOS 13.0, *))
    {
        viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    
    [self presentViewController:viewController animated:YES completion:completion];
}

#pragma mark - Private

- (void)clearCache
{
    [MXMediaManager clearCache];
    [MXKAttachment clearCache];
    [VoiceMessageAttachmentCacheManagerBridge clearCache];
    [URLPreviewService.shared clearStore];
}

#pragma mark - Spaces

-(void)openSpaceWithId:(NSString *)spaceId
{
    MXSession *session = mxSessionArray.firstObject;
    if ([session.spaceService getSpaceWithId:spaceId]) {
        [self restoreInitialDisplay:^{
            [self.delegate legacyAppDelegate:self didNavigateToSpaceWithId:spaceId];
        }];
    }
    else
    {
        MXWeakify(self);
        __block __weak id observer = [[NSNotificationCenter defaultCenter] addObserverForName:MXSpaceService.didBuildSpaceGraph object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            MXStrongifyAndReturnIfNil(self);
            
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
            
            if ([session.spaceService getSpaceWithId:spaceId]) {
                [self restoreInitialDisplay:^{
                    [self.delegate legacyAppDelegate:self didNavigateToSpaceWithId:spaceId];
                }];
            }
        }];
    }
}

#pragma mark - SpaceDetailPresenterDelegate

- (void)spaceDetailPresenterDidComplete:(SpaceDetailPresenter *)presenter
{
    self.spaceDetailPresenter = nil;
}

- (void)spaceDetailPresenter:(SpaceDetailPresenter *)presenter didOpenSpaceWithId:(NSString *)spaceId
{
    self.spaceDetailPresenter = nil;
    [self openSpaceWithId:spaceId];
}

- (void)spaceDetailPresenter:(SpaceDetailPresenter *)presenter didJoinSpaceWithId:(NSString *)spaceId
{
    self.spaceDetailPresenter = nil;
    [self openSpaceWithId:spaceId];
}

#pragma mark - Mandatory SSSS setup

- (void)presentSecureBackupSetupForSession:(MXSession*)mxSession
{
    MXLogDebug(@"[AppDelegate][Mandatory SSSS] presentSecureBackupSetupForSession");

    if (!secureBackupSetupCoordinatorBridgePresenter.isPresenting)
    {
        secureBackupSetupCoordinatorBridgePresenter = [[SecureBackupSetupCoordinatorBridgePresenter alloc] initWithSession:mxSession allowOverwrite:false];
        secureBackupSetupCoordinatorBridgePresenter.delegate = self;

        [secureBackupSetupCoordinatorBridgePresenter presentFrom:self.masterTabBarController animated:NO cancellable:NO];
    }
    else
    {
        MXLogDebug(@"[AppDelegate][Mandatory SSSS] presentSecureBackupSetupForSession: Controller already presented")
    }
}

#pragma mark - SecureBackupSetupCoordinatorBridgePresenterDelegate

- (void)secureBackupSetupCoordinatorBridgePresenterDelegateDidComplete:(SecureBackupSetupCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [secureBackupSetupCoordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    secureBackupSetupCoordinatorBridgePresenter = nil;
}

- (void)secureBackupSetupCoordinatorBridgePresenterDelegateDidCancel:(SecureBackupSetupCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [secureBackupSetupCoordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    secureBackupSetupCoordinatorBridgePresenter = nil;
}

@end
