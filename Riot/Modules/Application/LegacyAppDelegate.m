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

#import <MatrixKit/MatrixKit.h>

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

#import "Riot-Swift.h"
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

#define MAKE_STRING(x) #x
#define MAKE_NS_STRING(x) @MAKE_STRING(x)

NSString *const kAppDelegateDidTapStatusBarNotification = @"kAppDelegateDidTapStatusBarNotification";
NSString *const kAppDelegateNetworkStatusDidChangeNotification = @"kAppDelegateNetworkStatusDidChangeNotification";

NSString *const AppDelegateDidValidateEmailNotification = @"AppDelegateDidValidateEmailNotification";
NSString *const AppDelegateDidValidateEmailNotificationSIDKey = @"AppDelegateDidValidateEmailNotificationSIDKey";
NSString *const AppDelegateDidValidateEmailNotificationClientSecretKey = @"AppDelegateDidValidateEmailNotificationClientSecretKey";

NSString *const AppDelegateUniversalLinkDidChangeNotification = @"AppDelegateUniversalLinkDidChangeNotification";

@interface LegacyAppDelegate () <GDPRConsentViewControllerDelegate, KeyVerificationCoordinatorBridgePresenterDelegate, ServiceTermsModalCoordinatorBridgePresenterDelegate, PushNotificationServiceDelegate, SetPinCoordinatorBridgePresenterDelegate, CallPresenterDelegate, CallBarDelegate>
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

@property (strong, nonatomic) UIAlertController *mxInAppNotification;

@property (strong, nonatomic) UIAlertController *logoutConfirmation;

@property (weak, nonatomic) UIAlertController *gdprConsentNotGivenAlertController;
@property (weak, nonatomic) UIViewController *gdprConsentController;

@property (weak, nonatomic) UIAlertController *incomingKeyVerificationRequestAlertController;

@property (nonatomic, strong) ServiceTermsModalCoordinatorBridgePresenter *serviceTermsModalCoordinatorBridgePresenter;
@property (nonatomic, strong) SlidingModalPresenter *slidingModalPresenter;
@property (nonatomic, strong) SetPinCoordinatorBridgePresenter *setPinCoordinatorBridgePresenter;

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
@property (nonatomic, strong) CallPresenter *callPresenter;

@property (nonatomic, strong) MajorUpdateManager *majorUpdateManager;

@end

@implementation LegacyAppDelegate

#pragma mark -

+ (void)initialize
{
    NSLog(@"[AppDelegate] initialize");

    // Set static application settings
    [[AppConfiguration new] setupSettings];

    // Redirect NSLogs to files only if we are not debugging
    if (!isatty(STDERR_FILENO))
    {
        NSUInteger sizeLimit = 100 * 1024 * 1024; // 100MB
        [MXLogger redirectNSLogToFiles:YES numberOfFiles:50 sizeLimit:sizeLimit];
    }

    NSLog(@"[AppDelegate] initialize: Done");
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
    
    NSLog(@"The generated device token string is : %@",deviceTokenString);
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
        buildNumber = [NSString stringWithFormat:@"#%@", @(BUILD_NUMBER)];
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

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions
{
    // Create message sound
    NSURL *messageSoundURL = [[NSBundle mainBundle] URLForResource:@"message" withExtension:@"caf"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)messageSoundURL, &_messageSound);
    
    NSLog(@"[AppDelegate] willFinishLaunchingWithOptions: Done");

    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSDate *startDate = [NSDate date];
    
#ifdef DEBUG
    // log the full launchOptions only in DEBUG
    NSLog(@"[AppDelegate] didFinishLaunchingWithOptions: %@", launchOptions);
#else
    NSLog(@"[AppDelegate] didFinishLaunchingWithOptions");
#endif

    NSLog(@"[AppDelegate] didFinishLaunchingWithOptions: isProtectedDataAvailable: %@", @([application isProtectedDataAvailable]));

    _configuration = [AppConfiguration new];
    
    // Log app information
    NSString *appDisplayName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
    NSString* appVersion = [AppDelegate theDelegate].appVersion;
    NSString* build = [AppDelegate theDelegate].build;
    
    NSLog(@"------------------------------");
    NSLog(@"Application info:");
    NSLog(@"%@ version: %@", appDisplayName, appVersion);
    NSLog(@"MatrixKit version: %@", MatrixKitVersion);
    NSLog(@"MatrixSDK version: %@", MatrixSDKVersion);
    NSLog(@"Build: %@\n", build);
    NSLog(@"------------------------------\n");
    
    [self setupUserDefaults];

    // Set up theme
    ThemeService.shared.themeId = RiotSettings.shared.userInterfaceTheme;

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
    
    // Configure our analytics. It will indeed start if the option is enabled
    Analytics *analytics = [Analytics sharedInstance];
    [MXSDKOptions sharedInstance].analyticsDelegate = analytics;
    [DecryptionFailureTracker sharedInstance].delegate = [Analytics sharedInstance];
    
    MXBaseProfiler *profiler = [MXBaseProfiler new];
    profiler.analytics = analytics;
    [MXSDKOptions sharedInstance].profiler = profiler;
    
    [analytics start];

    self.localAuthenticationService = [[LocalAuthenticationService alloc] initWithPinCodePreferences:[PinCodePreferences shared]];
    
    self.callPresenter = [[CallPresenter alloc] init];
    self.callPresenter.delegate = self;

    self.pushNotificationStore = [PushNotificationStore new];
    self.pushNotificationService = [[PushNotificationService alloc] initWithPushNotificationStore:self.pushNotificationStore];
    self.pushNotificationService.delegate = self;
    
    // Add matrix observers, and initialize matrix sessions if the app is not launched in background.
    [self initMatrixSessions];
    
#ifdef CALL_STACK_JINGLE
    // Setup Jitsi
    [JitsiService.shared configureDefaultConferenceOptionsWith:BuildSettings.jitsiServerUrl];

    [JitsiService.shared application:application didFinishLaunchingWithOptions:launchOptions];
#endif
    
    self.majorUpdateManager = [MajorUpdateManager new];

    NSLog(@"[AppDelegate] didFinishLaunchingWithOptions: Done in %.0fms", [[NSDate date] timeIntervalSinceDate:startDate] * 1000);

    dispatch_async(dispatch_get_main_queue(), ^{
        [self configurePinCodeScreenFor:application createIfRequired:YES];
    });
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"[AppDelegate] applicationWillResignActive");
    
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
        [self.setPinCoordinatorBridgePresenter presentIn:self.window];
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
    
    [self.pushNotificationService applicationDidEnterBackground];
    
    // Pause profiling
    [MXSDKOptions.sharedInstance.profiler pause];
    
    // Analytics: Force to send the pending actions
    [[DecryptionFailureTracker sharedInstance] dispatch];
    [[Analytics sharedInstance] dispatch];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"[AppDelegate] applicationWillEnterForeground");
    
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

    [MXSDKOptions.sharedInstance.profiler resume];
    
    // Force each session to refresh here their publicised groups by user dictionary.
    // When these publicised groups are retrieved for a user, they are cached and reused until the app is backgrounded and enters in the foreground again
    for (MXSession *session in mxSessionArray)
    {
        [session markOutdatedPublicisedGroupsByUserData];
    }
    
    _isAppForeground = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"[AppDelegate] applicationDidBecomeActive");
    
    [self.pushNotificationService applicationDidBecomeActive];
    
    [self configurePinCodeScreenFor:application createIfRequired:NO];
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
            [self.setPinCoordinatorBridgePresenter presentIn:self.window];
        }
    }
    else
    {
        [self.setPinCoordinatorBridgePresenter dismiss];
        self.setPinCoordinatorBridgePresenter = nil;
        [self afterAppUnlockedByPin:application];
    }
}

- (void)afterAppUnlockedByPin:(UIApplication *)application
{
    NSLog(@"[AppDelegate] afterAppUnlockedByPin");
    
    // Check if there is crash log to send
    if (RiotSettings.shared.enableCrashReport)
    {
        [self checkExceptionToReport];
    }
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    // Check if an initial sync failure occured while the app was in background
    MXSession *mainSession = self.mxSessions.firstObject;
    if (mainSession.state == MXSessionStateInitialSyncFailed)
    {
        // Inform the end user why the app appears blank
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                             code:NSURLErrorCannotConnectToHost
                                         userInfo:@{NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"homeserver_connection_lost", @"Vector", nil)}];

        [self showErrorAsAlert:error];
    }
    
    // Register to GDPR consent not given notification
    [self registerUserConsentNotGivenNotification];
    
    // Register to identity server terms not signed notification
    [self registerIdentityServiceTermsNotSignedNotification];
    
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

    // Observe wrong backup version
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBackupStateDidChangeNotification:) name:kMXKeyBackupDidStateChangeNotification object:nil];

    // Resume all existing matrix sessions
    NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    for (MXKAccount *account in mxAccounts)
    {
        [account resume];
    }
    
    _isAppForeground = YES;

    if (@available(iOS 11.0, *))
    {
        // Riot has its own dark theme. Prevent iOS from applying its one
        [application keyWindow].accessibilityIgnoresInvertColors = YES;
    }
    
    [self handleAppState];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"[AppDelegate] applicationWillTerminate");
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    NSLog(@"[AppDelegate] applicationDidReceiveMemoryWarning");
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
                else if (wrongBackupVersionAlert)
                {
                    NSLog(@"[AppDelegate] restoreInitialDisplay: keep visible wrongBackupVersionAlert");
                    [self showNotificationAlert:wrongBackupVersionAlert];

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

- (void)keyBackupStateDidChangeNotification:(NSNotification *)notification
{
    MXKeyBackup *keyBackup = notification.object;

    if (keyBackup.state == MXKeyBackupStateWrongBackUpVersion)
    {
        if (wrongBackupVersionAlert)
        {
            [wrongBackupVersionAlert dismissViewControllerAnimated:NO completion:nil];
        }

        wrongBackupVersionAlert = [UIAlertController
                                   alertControllerWithTitle:NSLocalizedStringFromTable(@"e2e_key_backup_wrong_version_title", @"Vector", nil)

                                   message:NSLocalizedStringFromTable(@"e2e_key_backup_wrong_version", @"Vector", nil)

                                   preferredStyle:UIAlertControllerStyleAlert];

        MXWeakify(self);
        [wrongBackupVersionAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"e2e_key_backup_wrong_version_button_settings"]
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action)
                                             {
                                                 MXStrongifyAndReturnIfNil(self);
                                                 self->wrongBackupVersionAlert = nil;

                                                 // TODO: Open settings
                                             }]];

        [wrongBackupVersionAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"e2e_key_backup_wrong_version_button_wasme"]
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
        
        NSLog(@"[AppDelegate] Promt user to report crash:\n%@", description);

        // Ask the user to send a crash report
        [[RageShakeManager sharedManager] promptCrashReportInViewController:self.window.rootViewController];
    }
}

#pragma mark - PushNotificationServiceDelegate

- (void)pushNotificationService:(PushNotificationService *)pushNotificationService shouldNavigateToRoomWithId:(NSString *)roomId
{
    _lastNavigatedRoomIdFromPush = roomId;
    [self navigateToRoomById:roomId];
}

#pragma mark - Badge Count

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

    // Extract required parameters from the link
    NSArray<NSString*> *pathParams;
    NSMutableDictionary *queryParams;
    [self parseUniversalLinkFragment:webURL.absoluteString outPathParams:&pathParams outQueryParams:&queryParams];

    UniversalLink *newLink = [[UniversalLink alloc] initWithUrl:webURL pathParams:pathParams queryParams:queryParams];
    if (![_lastHandledUniversalLink isEqual:newLink])
    {
        _lastHandledUniversalLink = [[UniversalLink alloc] initWithUrl:webURL pathParams:pathParams queryParams:queryParams];
        //  notify this change
        [[NSNotificationCenter defaultCenter] postNotificationName:AppDelegateUniversalLinkDidChangeNotification object:nil];
    }

    if ([self handleServerProvionningLink:webURL])
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
        NSLog(@"[AppDelegate] handleUniversalLink: Validate link");
        
        // We just need to ping the link.
        // The app should be in the registration flow at the "waiting for email validation" polling state. The server
        // will indicate the email is validated through this polling API. Then, the app will go to the next flow step.
        NSURLSessionConfiguration *conf = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:conf];
        
        NSURLSessionDataTask * task = [urlSession dataTaskWithURL:webURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            NSLog(@"[AppDelegate] handleUniversalLink: Link validation response: %@\nData: %@", response,
                  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            
            if (error)
            {
                NSLog(@"[AppDelegate] handleUniversalLink: Link validation error: %@", error);
                [self showErrorAsAlert:error];
            }
        }];
        
        [task resume];
        
        return YES;
    }
    
    // Manage email validation link from Identity Server v1 or v2
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
                
                // Post a notification about email validation to make a chance to SettingsDiscoveryThreePidDetailsViewModel to make it discoverable or not by the identity server.
                if (clientSecret && sid)
                {
                    NSDictionary *userInfo = @{ AppDelegateDidValidateEmailNotificationClientSecretKey : clientSecret,
                                                AppDelegateDidValidateEmailNotificationSIDKey : sid };
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:AppDelegateDidValidateEmailNotification object:nil userInfo:userInfo];
                }
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
    
    // Make sure we have plain utf8 character for separators
    fragment = [fragment stringByRemovingPercentEncoding];
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
    NSString *groupId;
    
    // Check permalink to room or event
    if ([pathParams[0] isEqualToString:@"room"] && pathParams.count >= 2)
    {
        // The link is the form of "/room/[roomIdOrAlias]" or "/room/[roomIdOrAlias]/[eventId]"
        roomIdOrAlias = pathParams[1];
        
        // Is it a link to an event of a room?
        eventId = (pathParams.count >= 3) ? pathParams[2] : nil;
    }
    else if ([pathParams[0] isEqualToString:@"group"] && pathParams.count >= 2)
    {
        // The link is the form of "/group/[groupId]"
        groupId = pathParams[1];
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
                                            [fragment stringByReplacingOccurrencesOfString:[MXTools encodeURIComponent:roomIdOrAlias]
                                                                                withString:[MXTools encodeURIComponent:roomId]
                                            ];
                                    
                                    // The previous operation can fail because of percent encoding
                                    // TBH we are not clean on data inputs. For the moment, just give another try with no encoding
                                    // TODO: Have a dedicated module and tests to handle universal links (matrix.to, email link, etc)
                                    if ([newUniversalLinkFragment isEqualToString:fragment])
                                    {
                                        newUniversalLinkFragment =
                                        [fragment stringByReplacingOccurrencesOfString:roomIdOrAlias
                                                                            withString:[MXTools encodeURIComponent:roomId]];
                                    }
                                    
                                    if (![newUniversalLinkFragment isEqualToString:fragment])
                                    {
                                        universalLinkFragmentPendingRoomAlias = @{roomId: roomIdOrAlias};
                                        
                                        [self handleUniversalLinkFragment:newUniversalLinkFragment];
                                    }
                                    else
                                    {
                                        // Do not continue. Else we will loop forever
                                        NSLog(@"[AppDelegate] Universal link: Error: Cannot resolve alias in %@ to the room id %@", fragment, roomId);
                                    }
                                }
                                
                            } failure:^(NSError *error) {
                                NSLog(@"[AppDelegate] Universal link: Error: The homeserver failed to resolve the room alias (%@)", roomIdOrAlias);

                                [homeViewController stopActivityIndicator];

                                NSString *errorMessage = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_does_not_exist", @"Vector", nil), roomIdOrAlias];

                                [self showAlertWithTitle:nil message:errorMessage];
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
                            
                            RoomPreviewData *roomPreviewData = [[RoomPreviewData alloc] initWithRoomId:roomIdOrAlias
                                                                                            andSession:account.mxSession];
                            if (queryParams)
                            {
                                roomPreviewData.viaServers = queryParams[@"via"];
                            }
                            
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
    else if (groupId)
    {
        // @FIXME: In case of multi-account, ask the user which one to use
        MXKAccount* account = accountManager.activeAccounts.firstObject;
        if (account)
        {
            MXGroup *group = [account.mxSession groupWithGroupId:groupId];
            
            if (!group)
            {
                // Create a group instance to display its preview
                group = [[MXGroup alloc] initWithGroupId:groupId];
            }
            
            // Display the group details
            [self showGroup:group withMatrixSession:account.mxSession];
            
            continueUserActivity = YES;
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
    // Check whether this is a registration links.
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
        pathParams2[i] = [pathParams2[i] stringByRemovingPercentEncoding];
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
            NSString *key = [keyValue componentsSeparatedByString:@"="][0];
            
            // Get the parameter value
            NSString *value = [keyValue componentsSeparatedByString:@"="][1];
            if (value.length)
            {
                value = [value stringByReplacingOccurrencesOfString:@"+" withString:@" "];
                value = [value stringByRemovingPercentEncoding];

                if ([key isEqualToString:@"via"])
                {
                    // Special case the via parameter
                    // As we can have several of them, store each value into an array
                    if (!queryParams[key])
                    {
                        queryParams[key] = [NSMutableArray array];
                    }

                    [queryParams[key] addObject:value];
                }
                else
                {
                    queryParams[key] = value;
                }
            }
        }
    }
    
    *outPathParams = pathParams;
    *outQueryParams = queryParams;
}


- (BOOL)handleServerProvionningLink:(NSURL*)link
{
    NSLog(@"[AppDelegate] handleServerProvionningLink: %@", link);

    NSString *homeserver, *identityServer;
    [self parseServerProvionningLink:link homeserver:&homeserver identityServer:&identityServer];

    if (homeserver)
    {
        if ([MXKAccountManager sharedManager].activeAccounts.count)
        {
            [self displayServerProvionningLinkBuyAlreadyLoggedInAlertWithCompletion:^(BOOL logout) {

                NSLog(@"[AppDelegate] handleServerProvionningLink: logoutWithConfirmation: logout: %@", @(logout));
                if (logout)
                {
                    [self logoutWithConfirmation:NO completion:^(BOOL isLoggedOut) {
                        [self handleServerProvionningLink:link];
                    }];
                }
            }];
        }
        else
        {
            [_masterTabBarController showAuthenticationScreen];
            [_masterTabBarController.authViewController showCustomHomeserver:homeserver andIdentityServer:identityServer];
        }

        return YES;
    }

    return NO;
}

- (void)parseServerProvionningLink:(NSURL*)link homeserver:(NSString**)homeserver identityServer:(NSString**)identityServer
{
    if ([link.path isEqualToString:@"/"])
    {
        NSURLComponents *linkURLComponents = [NSURLComponents componentsWithURL:link resolvingAgainstBaseURL:NO];
        for (NSURLQueryItem *item in linkURLComponents.queryItems)
        {
            if ([item.name isEqualToString:@"hs_url"])
            {
                *homeserver = item.value;
            }
            else if ([item.name isEqualToString:@"is_url"])
            {
                *identityServer = item.value;
                break;
            }
        }
    }
    else
    {
        NSLog(@"[AppDelegate] parseServerProvionningLink: Error: Unknown path: %@", link.path);
    }


    NSLog(@"[AppDelegate] parseServerProvionningLink: homeserver: %@ - identityServer: %@", *homeserver, *identityServer);
}

- (void)displayServerProvionningLinkBuyAlreadyLoggedInAlertWithCompletion:(void (^)(BOOL logout))completion
{
    // Ask confirmation
    self.logoutConfirmation = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"error_user_already_logged_in", @"Vector", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];

    [self.logoutConfirmation addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"settings_sign_out", @"Vector", nil)
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action)
                                        {
                                            self.logoutConfirmation = nil;
                                            completion(YES);
                                        }]];

    [self.logoutConfirmation addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                                style:UIAlertActionStyleCancel
                                                              handler:^(UIAlertAction * action)
                                        {
                                            self.logoutConfirmation = nil;
                                            completion(NO);
                                        }]];

    [self.logoutConfirmation mxk_setAccessibilityIdentifier: @"AppDelegateLogoutConfirmationAlert"];
    [self showNotificationAlert:self.logoutConfirmation];
}

#pragma mark - Matrix sessions handling

- (void)initMatrixSessions
{
    NSLog(@"[AppDelegate] initMatrixSessions");

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
            
            // Look for the account related to this session.
            NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
            for (MXKAccount *account in mxAccounts)
            {
                if (account.mxSession == mxSession)
                {
                    // Enable inApp notifications (if they are allowed for this account).
                    [self enableInAppNotificationsForAccount:account];
                    break;
                }
            }
            
            [self.configuration setupSettingsWhenLoadedFor:mxSession];
            
            // Register to user new device sign in notification
            [self registerUserDidSignInOnNewDeviceNotificationForSession:mxSession];
            
            [self registerDidChangeCrossSigningKeysNotificationForSession:mxSession];
            
            // Register to new key verification request
            [self registerNewRequestNotificationForSession:mxSession];
            
            [self checkLocalPrivateKeysInSession:mxSession];
            
            [self.pushNotificationService checkPushKitPushersInSession:mxSession];
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

            NSLog(@"[AppDelegate][Push] didAddAccountNotification: isPushRegistered: %@", @(isPushRegistered));

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
        if (!account.isSoftLogout)
        {
            [account removeObserver:self forKeyPath:@"enableInAppNotifications"];
        }

        // Clear Modular data
        [[WidgetManager sharedManager] deleteDataForUser:account.mxCredentials.userId];
        
        // Logout the app when there is no available account
        if (![MXKAccountManager sharedManager].accounts.count)
        {
            [self logoutWithConfirmation:NO completion:nil];
        }
    }];

    // Add observer to handle soft logout
    [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidSoftlogoutAccountNotification  object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

        MXKAccount *account = notif.object;
        [self removeMatrixSession:account.mxSession];

        // Return to authentication screen
        [self.masterTabBarController showAuthenticationScreenAfterSoftLogout:account.mxCredentials];
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
    NSLog(@"[AppDelegate] initMatrixSessions: prepareSessionForActiveAccounts (app state: %tu)", [[UIApplication sharedApplication] applicationState]);
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
        // But wait a bit that our launch animation screen is ready to show and
        // displayed if needed. As the processing in MXKContactManager can lock
        // the UI thread for several seconds, it is better to show the animation
        // during this blocking task.
        dispatch_after(dispatch_walltime(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [[MXKContactManager sharedManager] addMatrixSession:mxSession];

            // Load the local contacts on first account
            if ([MXKAccountManager sharedManager].accounts.count == 1)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self refreshLocalContacts];
                });
            }
        });
        
        // Update home data sources
        [_masterTabBarController addMatrixSession:mxSession];

        // Register the session to the widgets manager
        [[WidgetManager sharedManager] addMatrixSession:mxSession];
        
        // register the session to the call service
        [_callPresenter addMatrixSession:mxSession];
        
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
    
    // remove session from the call service
    [_callPresenter removeMatrixSession:mxSession];

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
        
        NSString *message = NSLocalizedStringFromTable(@"settings_sign_out_confirmation", @"Vector", nil);
        
        // If the user has encrypted rooms, warn he will lose his e2e keys
        MXSession *session = self.mxSessions.firstObject;
        for (MXRoom *room in session.rooms)
        {
            if (room.summary.isEncrypted)
            {
                message = [message stringByAppendingString:[NSString stringWithFormat:@"\n\n%@", NSLocalizedStringFromTable(@"settings_sign_out_e2e_warn", @"Vector", nil)]];
                break;
            }
        }
        
        // Ask confirmation
        self.logoutConfirmation = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"settings_sign_out", @"Vector", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
        
        [self.logoutConfirmation addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"settings_sign_out", @"Vector", nil)
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
        
        [self.logoutConfirmation addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
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
            if (isLoggedOut)
            {
                [RiotSettings.shared reset];
            }
            completion (YES);
        }
    }];
}

- (void)logoutSendingRequestServer:(BOOL)sendLogoutServerRequest
                        completion:(void (^)(BOOL isLoggedOut))completion
{
    [self.pushNotificationService deregisterRemoteNotifications];

    // Clear cache
    [MXMediaManager clearCache];
    
    // Reset key backup banner preferences
    [SecureBackupBannerPreferences.shared reset];
    
    // Reset key verification banner preferences
    [CrossSigningBannerPreferences.shared reset];
    
    // Reset user pin code
    [PinCodePreferences.shared reset];
    
    //  Reset push notification store
    [self.pushNotificationStore reset];
    
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
        
        if (completion)
        {
            completion (YES);
        }
        
        // Return to authentication screen
        [_masterTabBarController showAuthenticationScreen];
        
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
    else if ([@"enableInAppNotifications" isEqualToString:keyPath] && [object isKindOfClass:[MXKAccount class]])
    {
        [self enableInAppNotificationsForAccount:(MXKAccount*)object];
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
        BOOL isLaunching = NO;
        
        if (_masterTabBarController.authenticationInProgress)
        {
            NSLog(@"[AppDelegate] handleAppState: Authentication still in progress");
                  
            // Wait for the return of masterTabBarControllerDidCompleteAuthentication
            isLaunching = YES;            
        }
        else
        {
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
                    
                    if (mainSession.crypto.crossSigning && mainSession.crypto.crossSigning.state == MXCrossSigningStateCrossSigningExists)
                    {
                        [mainSession.crypto setOutgoingKeyRequestsEnabled:NO onComplete:nil];
                    }
                    break;
                default:
                    isLaunching = NO;
                    break;
            }
        }
        
        NSLog(@"[AppDelegate] handleAppState: isLaunching: %@", isLaunching ? @"YES" : @"NO");
        
        if (isLaunching)
        {
            NSLog(@"[AppDelegate] handleAppState: LaunchLoadingView");
            [self showLaunchAnimation];
            return;
        }

        [self hideLaunchAnimation];
        
        if (self.setPinCoordinatorBridgePresenter)
        {
            NSLog(@"[AppDelegate] handleAppState: PIN code is presented. Do not go further");
            return;
        }
        
        if (mainSession.crypto.crossSigning)
        {
            // Get the up-to-date cross-signing state
            MXWeakify(self);
            [mainSession.crypto.crossSigning refreshStateWithSuccess:^(BOOL stateUpdated) {
                MXStrongifyAndReturnIfNil(self);
                
                NSLog(@"[AppDelegate] handleAppState: crossSigning.state: %@", @(mainSession.crypto.crossSigning.state));
                
                switch (mainSession.crypto.crossSigning.state)
                {
                    case MXCrossSigningStateCrossSigningExists:
                        NSLog(@"[AppDelegate] handleAppState: presentVerifyCurrentSessionAlertIfNeededWithSession");
                        [self.masterTabBarController presentVerifyCurrentSessionAlertIfNeededWithSession:mainSession];
                        break;
                    case MXCrossSigningStateCanCrossSign:
                        NSLog(@"[AppDelegate] handleAppState: presentReviewUnverifiedSessionsAlertIfNeededWithSession");
                        [self.masterTabBarController presentReviewUnverifiedSessionsAlertIfNeededWithSession:mainSession];
                        break;
                    default:
                        break;
                }
            } failure:^(NSError * _Nonnull error) {
                NSLog(@"[AppDelegate] handleAppState: crossSigning.state: %@. Error: %@", @(mainSession.crypto.crossSigning.state), error);
            }];
        }
        
        // TODO: We should wait that cross-signing screens are done before going further but it seems fine. Those screens
        // protect each other.
        
        // This is the time to check existing requests
        NSLog(@"[AppDelegate] handleAppState: Check pending verification requests");
        [self checkPendingRoomKeyRequests];
        [self checkPendingIncomingKeyVerificationsInSession:mainSession];
            
        // TODO: When we will have an application state, we will do all of this in a dedicated initialisation state
        // For the moment, reuse an existing boolean to avoid register things several times
        if (!incomingKeyVerificationObserver)
        {
            NSLog(@"[AppDelegate] handleAppState: Set up observers for the crypto module");
            
            // Enable listening of incoming key share requests
            [self enableRoomKeyRequestObserver:mainSession];
            
            // Enable listening of incoming key verification requests
            [self enableIncomingKeyVerificationObserver:mainSession];
        }
    }
}

- (void)showLaunchAnimation
{
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    
    if (!launchAnimationContainerView && window)
    {
        NSLog(@"[AppDelegate] showLaunchAnimation");
        
        LaunchLoadingView *launchLoadingView = [LaunchLoadingView instantiate];
        launchLoadingView.frame = window.bounds;
        [launchLoadingView updateWithTheme:ThemeService.shared.theme];
        launchLoadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [window addSubview:launchLoadingView];
        
        launchAnimationContainerView = launchLoadingView;
        
        [MXSDKOptions.sharedInstance.profiler startMeasuringTaskWithName:kMXAnalyticsStartupLaunchScreen
                                                        category:kMXAnalyticsStartupCategory];
    }
}

- (void)hideLaunchAnimation
{
    if (launchAnimationContainerView)
    {
        id<MXProfiler> profiler = MXSDKOptions.sharedInstance.profiler;
        MXTaskProfile *launchTaskProfile = [profiler taskProfileWithName:kMXAnalyticsStartupLaunchScreen category:kMXAnalyticsStartupCategory];
        if (launchTaskProfile)
        {
            [profiler stopMeasuringTaskWithProfile:launchTaskProfile];
            
            NSLog(@"[AppDelegate] hideLaunchAnimation: LaunchAnimation was shown for %.3fms", launchTaskProfile.duration * 1000);
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
    id<MXCryptoStore> cryptoStore = mxSession.crypto.store;
    NSUInteger keysCount = 0;
    if ([cryptoStore secretWithSecretId:MXSecretId.keyBackup])
    {
        keysCount++;
    }
    if ([cryptoStore secretWithSecretId:MXSecretId.crossSigningUserSigning])
    {
        keysCount++;
    }
    if ([cryptoStore secretWithSecretId:MXSecretId.crossSigningSelfSigning])
    {
        keysCount++;
    }
    
    if ((keysCount > 0 && keysCount < 3)
        || (mxSession.crypto.crossSigning.canTrustCrossSigning && !mxSession.crypto.crossSigning.canCrossSign))
    {
        // We should have 3 of them. If not, request them again as mitigation
        NSLog(@"[AppDelegate] checkLocalPrivateKeysInSession: request keys because keysCount = %@", @(keysCount));
        [mxSession.crypto requestAllPrivateKeys];
    }
}

- (void)authenticationDidComplete
{
    [self handleAppState];
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
                                    // Play message sound
                                    AudioServicesPlaySystemSound(_messageSound);
                                }
                            }
                        }
                        
                        MXRoomSummary *roomSummary = [account.mxSession roomSummaryWithRoomId:event.roomId];
                        
                        __weak typeof(self) weakSelf = self;
                        self.mxInAppNotification = [UIAlertController alertControllerWithTitle:roomSummary.displayname
                                                                                       message:messageText
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        
                        [self.mxInAppNotification addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                                                     style:UIAlertActionStyleCancel
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

- (void)navigateToRoomById:(NSString *)roomId
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
            NSLog(@"[AppDelegate][Push] navigateToRoomById: open the roomViewController %@", roomId);

            [self showRoom:roomId andEventId:nil withMatrixSession:dedicatedAccount.mxSession];
        }
        else
        {
            NSLog(@"[AppDelegate][Push] navigateToRoomById : no linked session / account has been found.");
        }
    }
}

- (void)showRoom:(NSString*)roomId andEventId:(NSString*)eventId withMatrixSession:(MXSession*)mxSession restoreInitialDisplay:(BOOL)restoreInitialDisplay completion:(void (^)(void))completion
{
    void (^selectRoom)(void) = ^() {
        // Select room to display its details (dispatch this action in order to let TabBarController end its refresh)
        [self.masterTabBarController selectRoomWithId:roomId andEventId:eventId inMatrixSession:mxSession completion:^{
            
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

- (void)showRoom:(NSString*)roomId andEventId:(NSString*)eventId withMatrixSession:(MXSession*)mxSession restoreInitialDisplay:(BOOL)restoreInitialDisplay
{
    [self showRoom:roomId andEventId:eventId withMatrixSession:mxSession restoreInitialDisplay:restoreInitialDisplay completion:nil];
}

- (void)showRoom:(NSString*)roomId andEventId:(NSString*)eventId withMatrixSession:(MXSession*)mxSession
{
    [self showRoom:roomId andEventId:eventId withMatrixSession:mxSession restoreInitialDisplay:YES completion:nil];
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

            void (^onFailure)(NSError *) = ^(NSError *error){
                NSLog(@"[AppDelegate] Create direct chat failed");
                //Alert user
                [self showErrorAsAlert:error];

                if (completion)
                {
                    completion();
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

                    // Open created room
                    [self showRoom:room.roomId andEventId:nil withMatrixSession:mxSession];

                    if (completion)
                    {
                        completion();
                    }

                } failure:onFailure];

            } failure:onFailure];
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
    if (!BuildSettings.allowLocalContactsAccess)
    {
        return;
    }
    
    // Do not scan local contacts in background if the user has not decided yet about using
    // an identity server
    BOOL doRefreshLocalContacts = NO;
    for (MXSession *session in mxSessionArray)
    {
        if (session.hasAccountDataIdentityServerValue)
        {
            doRefreshLocalContacts = YES;
            break;
        }
    }

    // Check whether the application is allowed to access the local contacts.
    if (doRefreshLocalContacts
        && [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusAuthorized)
    {
        // Check the user permission for syncing local contacts. This permission was handled independently on previous application version.
        if (![MXKAppSettings standardAppSettings].syncLocalContacts)
        {
            // Check whether it was not requested yet.
            if (![MXKAppSettings standardAppSettings].syncLocalContactsPermissionRequested)
            {
                [MXKAppSettings standardAppSettings].syncLocalContactsPermissionRequested = YES;
                
                [MXKContactManager requestUserConfirmationForLocalContactsSyncInViewController:self.presentedViewController completionHandler:^(BOOL granted) {
                    
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

#pragma mark - Matrix Groups handling

- (void)showGroup:(MXGroup*)group withMatrixSession:(MXSession*)mxSession
{
    [self restoreInitialDisplay:^{
        
        // Select group to display its details (dispatch this action in order to let TabBarController end its refresh)
        [_masterTabBarController selectGroup:group inMatrixSession:mxSession];
        
    }];
}

- (void)promptForStunServerFallback
{
    [_errorNotification dismissViewControllerAnimated:NO completion:nil];

    NSString *stunFallbackHost = BuildSettings.stunServerFallbackUrlString;
    // Remove "stun:"
    stunFallbackHost = [stunFallbackHost componentsSeparatedByString:@":"].lastObject;

    MXSession *mainSession = self.mxSessions.firstObject;
    NSString *homeServerName = mainSession.matrixRestClient.credentials.homeServerName;

    NSString *message = [NSString stringWithFormat:@"%@\n\n%@",
                         [NSString stringWithFormat:NSLocalizedStringFromTable(@"call_no_stun_server_error_message_1", @"Vector", nil), homeServerName],
                         [NSString stringWithFormat: NSLocalizedStringFromTable(@"call_no_stun_server_error_message_2", @"Vector", nil), stunFallbackHost]];

    _errorNotification = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"call_no_stun_server_error_title", @"Vector", nil)
                                                             message:message
                                                      preferredStyle:UIAlertControllerStyleAlert];

    [_errorNotification addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat: NSLocalizedStringFromTable(@"call_no_stun_server_error_use_fallback_button", @"Vector", nil), stunFallbackHost]
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {

                                                             RiotSettings.shared.allowStunServerFallback = YES;
                                                             mainSession.callManager.fallbackSTUNServer = BuildSettings.stunServerFallbackUrlString;

                                                             [AppDelegate theDelegate].errorNotification = nil;
                                                         }]];

    [_errorNotification addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
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

#pragma mark - Jitsi call

- (void)displayJitsiViewControllerWithWidget:(Widget*)jitsiWidget andVideo:(BOOL)video
{
#ifdef CALL_STACK_JINGLE
    if (!_jitsiViewController)
    {
        MXWeakify(self);
        [self checkPermissionForNativeWidget:jitsiWidget fromUrl:JitsiService.shared.serverURL completion:^(BOOL granted) {
            MXStrongifyAndReturnIfNil(self);
            if (!granted)
            {
                return;
            }

            self->_jitsiViewController = [JitsiViewController jitsiViewController];

            [self->_jitsiViewController openWidget:jitsiWidget withVideo:video success:^{

                self->_jitsiViewController.delegate = self;
                [self presentJitsiViewController:nil];

            } failure:^(NSError *error) {

                self->_jitsiViewController = nil;

                [self showAlertWithTitle:nil message:NSLocalizedStringFromTable(@"call_jitsi_error", @"Vector", nil)];
            }];
        }];
    }
    else
    {
        [self showAlertWithTitle:nil message:NSLocalizedStringFromTable(@"call_already_displayed", @"Vector", nil)];
    }
#else
    [self showAlertWithTitle:nil message:[NSBundle mxk_localizedStringForKey:@"not_supported_yet"]];
#endif
}

- (void)presentJitsiViewController:(void (^)(void))completion
{
    [self removeCallStatusBar];

    if (_jitsiViewController)
    {
        if (@available(iOS 13.0, *))
        {
            _jitsiViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        }

        [self presentViewController:_jitsiViewController animated:YES completion:completion];
    }
}

- (void)jitsiViewController:(JitsiViewController *)jitsiViewController dismissViewJitsiController:(void (^)(void))completion
{
    if (jitsiViewController == _jitsiViewController)
    {
        [_jitsiViewController dismissViewControllerAnimated:YES completion:completion];
        _jitsiViewController = nil;

        [self removeCallStatusBar];
    }
}

- (void)jitsiViewController:(JitsiViewController *)jitsiViewController goBackToApp:(void (^)(void))completion
{
    if (jitsiViewController == _jitsiViewController)
    {
        [_jitsiViewController dismissViewControllerAnimated:YES completion:^{

            MXRoom *room = [_jitsiViewController.widget.mxSession roomWithRoomId:_jitsiViewController.widget.roomId];
            NSString *btnTitle = [NSString stringWithFormat:NSLocalizedStringFromTable(@"active_call_details", @"Vector", nil), room.summary.displayname];
            [self updateCallStatusBar:btnTitle];

            if (completion)
            {
                completion();
            }
        }];
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
                 NSLog(@"[WidgetVC] setPermissionForWidget failed. Error: %@", error);
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
    
    NSString *widgetCreatorUserId = widget.widgetEvent.sender ?: NSLocalizedStringFromTable(@"room_participants_unknown", @"Vector", nil);
    
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
                                              NSLocalizedStringFromTable(@"room_widget_permission_display_name_permission", @"Vector", nil),
                                              NSLocalizedStringFromTable(@"room_widget_permission_avatar_url_permission", @"Vector", nil)
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


#pragma mark - Call status handling

/// Returns a suitable height for call status bar. Considers safe area insets if available and notch status.
- (CGFloat)calculateCallStatusBarHeight
{
    CGFloat result = CALL_STATUS_BAR_HEIGHT;
    if (@available(iOS 11.0, *))
    {
        if (UIDevice.currentDevice.hasNotch)
        {
            //  this device has a notch (iPhone X +)
            result += UIApplication.sharedApplication.keyWindow.safeAreaInsets.top;
        }
    }
    return result;
}

- (void)updateCallStatusBar:(NSString*)title
{
    if (_callBar)
    {
        _callBar.title = title;
        return;
    }
    // Add a call status bar
    CGSize topBarSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width, [self calculateCallStatusBarHeight]);

    _callStatusBarWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, topBarSize.width, topBarSize.height)];
    _callStatusBarWindow.windowLevel = UIWindowLevelStatusBar;
    
    // Create statusBarButton
    _callBar = [CallBar instantiate];
    _callBar.frame = CGRectMake(0, 0, topBarSize.width, topBarSize.height);
    _callBar.title = title;
    _callBar.backgroundColor = ThemeService.shared.theme.tintColor;
    _callBar.delegate = self;
    
    // Place button into the new window
    [_callBar setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_callStatusBarWindow addSubview:_callBar];
    
    // Force callBar to fill the window (to handle auto-layout in case of screen rotation)
    [_callBar.widthAnchor constraintEqualToAnchor:_callStatusBarWindow.widthAnchor].active = YES;
    [_callBar.heightAnchor constraintEqualToAnchor:_callStatusBarWindow.heightAnchor].active = YES;

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
        [_callBar removeFromSuperview];
        _callBar = nil;
        _callStatusBarWindow = nil;
        
        [self statusBarDidChangeFrame];
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
        CGFloat callStatusBarHeight = [self calculateCallStatusBarHeight];

        UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
        
        switch (statusBarOrientation)
        {
            case UIInterfaceOrientationLandscapeLeft:
            {
                _callStatusBarWindow.frame = CGRectMake(-rootControllerFrame.size.width / 2, -callStatusBarHeight / 2, rootControllerFrame.size.width, callStatusBarHeight);
                _callStatusBarWindow.transform = CGAffineTransformMake(0, -1, 1, 0, callStatusBarHeight / 2, rootControllerFrame.size.width / 2);
                break;
            }
            case UIInterfaceOrientationLandscapeRight:
            {
                _callStatusBarWindow.frame = CGRectMake(-rootControllerFrame.size.width / 2, -callStatusBarHeight / 2, rootControllerFrame.size.width, callStatusBarHeight);
                _callStatusBarWindow.transform = CGAffineTransformMake(0, 1, -1, 0, rootControllerFrame.size.height - callStatusBarHeight / 2, rootControllerFrame.size.width / 2);
                break;
            }
            default:
            {
                _callStatusBarWindow.transform = CGAffineTransformIdentity;
                _callStatusBarWindow.frame = CGRectMake(0, 0, rootControllerFrame.size.width, callStatusBarHeight);
                break;
            }
        }

        // Apply the vertical offset due to call status bar
        rootControllerFrame.origin.y = callStatusBarHeight;
        rootControllerFrame.size.height -= callStatusBarHeight;
    }
    
    rootController.view.frame = rootControllerFrame;
    if (rootController.presentedViewController)
    {
        rootController.presentedViewController.view.frame = rootControllerFrame;
    }
    [rootController.view setNeedsLayout];
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
                                             
                                             NSString *appDisplayName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
                                             
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
                                                     @"version": kMXCallVersion,
                                                     @"party_id": mxSession.myDeviceId
                                                 };
                                                 
                                                 [mxSession.matrixRestClient sendEventToRoom:event.roomId eventType:kMXEventTypeStringCallReject content:content txnId:nil success:nil failure:^(NSError *error) {
                                                     NSLog(@"[AppDelegate] enableNoVoIPOnMatrixSession: ERROR: Cannot send m.call.reject event.");
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
                                         case MXEventTypeCallReject:
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
        NSLog(@"[AppDelegate] checkPendingRoomKeyRequestsInSession called while the app is not active. Ignore it.");
        return;
    }

    MXWeakify(self);
    [mxSession.crypto pendingKeyRequests:^(MXUsersDevicesMap<NSArray<MXIncomingRoomKeyRequest *> *> *pendingKeyRequests) {
        
        MXStrongifyAndReturnIfNil(self);
        NSLog(@"[AppDelegate] checkPendingRoomKeyRequestsInSession: cross-signing state: %ld, pendingKeyRequests.count: %@. Already displayed: %@",
              mxSession.crypto.crossSigning.state,
              @(pendingKeyRequests.count),
              self->roomKeyRequestViewController ? @"YES" : @"NO");

        if (!mxSession.crypto.crossSigning || mxSession.crypto.crossSigning.state == MXCrossSigningStateNotBootstrapped)
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
                    NSLog(@"[AppDelegate] checkPendingRoomKeyRequestsInSession: Cancel current dialog");

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
            [mxSession.crypto downloadKeys:@[userId] forceDownload:NO success:^(MXUsersDevicesMap<MXDeviceInfo *> *usersDevicesInfoMap, NSDictionary<NSString *,MXCrossSigningInfo *> *crossSigningKeysMap) {
                
                MXStrongifyAndReturnIfNil(self);
                MXDeviceInfo *deviceInfo = [usersDevicesInfoMap objectForDevice:deviceId forUser:userId];
                if (deviceInfo)
                {
                    if (!mxSession.crypto.crossSigning || mxSession.crypto.crossSigning.state == MXCrossSigningStateNotBootstrapped)
                    {
                        BOOL wasNewDevice = (deviceInfo.trustLevel.localVerificationStatus == MXDeviceUnknown);
                        
                        void (^openDialog)(void) = ^void()
                        {
                            NSLog(@"[AppDelegate] checkPendingRoomKeyRequestsInSession: Open dialog for %@", deviceInfo);

                            self->roomKeyRequestViewController = [[RoomKeyRequestViewController alloc] initWithDeviceInfo:deviceInfo wasNewDevice:wasNewDevice andMatrixSession:mxSession onComplete:^{

                                self->roomKeyRequestViewController = nil;

                                // Check next pending key request, if any
                                [self checkPendingRoomKeyRequests];
                            }];

                            [self->roomKeyRequestViewController show];
                        };

                        // If the device was new before, it's not any more.
                        if (wasNewDevice)
                        {
                            [mxSession.crypto setDeviceVerification:MXDeviceUnverified forDevice:deviceId ofUser:userId success:openDialog failure:nil];
                        }
                        else
                        {
                            openDialog();
                        }
                    }
                    else if (deviceInfo.trustLevel.isVerified)
                    {
                        [mxSession.crypto acceptAllPendingKeyRequestsFromUser:userId andDevice:deviceId onComplete:^{
                            [self checkPendingRoomKeyRequests];
                        }];
                    }
                    else
                    {
                        [mxSession.crypto ignoreAllPendingKeyRequestsFromUser:userId andDevice:deviceId onComplete:^{
                            [self checkPendingRoomKeyRequests];
                        }];
                    }
                }
                else
                {
                    NSLog(@"[AppDelegate] checkPendingRoomKeyRequestsInSession: No details found for device %@:%@", userId, deviceId);
                    [mxSession.crypto ignoreAllPendingKeyRequestsFromUser:userId andDevice:deviceId onComplete:^{
                        [self checkPendingRoomKeyRequests];
                    }];
                }
            } failure:^(NSError *error) {
                // Retry later
                NSLog(@"[AppDelegate] checkPendingRoomKeyRequestsInSession: Failed to download device keys. Retry");
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
         if ([object isKindOfClass:MXIncomingSASTransaction.class])
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
        NSLog(@"[AppDelegate][MXKeyVerification] checkPendingIncomingKeyVerificationsInSession: called while the app is not active. Ignore it.");
        return;
    }

    [mxSession.crypto.keyVerificationManager transactions:^(NSArray<MXKeyVerificationTransaction *> * _Nonnull transactions) {

        NSLog(@"[AppDelegate][MXKeyVerification] checkPendingIncomingKeyVerificationsInSession: transactions: %@", transactions);

        for (MXKeyVerificationTransaction *transaction in transactions)
        {
            if (transaction.isIncoming)
            {
                MXIncomingSASTransaction *incomingTransaction = (MXIncomingSASTransaction*)transaction;
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

- (BOOL)presentIncomingKeyVerificationRequest:(MXKeyVerificationRequest*)incomingKeyVerificationRequest
                                    inSession:(MXSession*)session
{
    BOOL presented = NO;
    
    if (!keyVerificationCoordinatorBridgePresenter.isPresenting)
    {
        NSLog(@"[AppDelegate] presentIncomingKeyVerificationRequest");
        
        keyVerificationCoordinatorBridgePresenter = [[KeyVerificationCoordinatorBridgePresenter alloc] initWithSession:session];
        keyVerificationCoordinatorBridgePresenter.delegate = self;
        
        [keyVerificationCoordinatorBridgePresenter presentFrom:self.presentedViewController incomingKeyVerificationRequest:incomingKeyVerificationRequest animated:YES];
        
        presented = YES;
    }
    else
    {
        NSLog(@"[AppDelegate][MXKeyVerification] presentIncomingKeyVerificationRequest: Controller already presented.");
    }
    
    return presented;
}

- (BOOL)presentIncomingKeyVerification:(MXIncomingSASTransaction*)transaction inSession:(MXSession*)mxSession
{
    NSLog(@"[AppDelegate][MXKeyVerification] presentIncomingKeyVerification: %@", transaction);

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
        NSLog(@"[AppDelegate][MXKeyVerification] presentIncomingKeyVerification: Controller already presented.");
    }
    return presented;
}

- (BOOL)presentUserVerificationForRoomMember:(MXRoomMember*)roomMember session:(MXSession*)mxSession
{
    NSLog(@"[AppDelegate][MXKeyVerification] presentUserVerificationForRoomMember: %@", roomMember);
    
    BOOL presented = NO;
    if (!keyVerificationCoordinatorBridgePresenter.isPresenting)
    {
        keyVerificationCoordinatorBridgePresenter = [[KeyVerificationCoordinatorBridgePresenter alloc] initWithSession:mxSession];
        keyVerificationCoordinatorBridgePresenter.delegate = self;
        
        [keyVerificationCoordinatorBridgePresenter presentFrom:self.presentedViewController roomMember:roomMember animated:YES];
        
        presented = YES;
    }
    else
    {
        NSLog(@"[AppDelegate][MXKeyVerification] presentUserVerificationForRoomMember: Controller already presented.");
    }
    return presented;
}

- (BOOL)presentSelfVerificationForOtherDeviceId:(NSString*)deviceId inSession:(MXSession*)mxSession
{
    NSLog(@"[AppDelegate][MXKeyVerification] presentSelfVerificationForOtherDeviceId: %@", deviceId);
    
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
        NSLog(@"[AppDelegate][MXKeyVerification] presentUserVerificationForRoomMember: Controller already presented.");
    }
    return presented;
}

- (void)keyVerificationCoordinatorBridgePresenterDelegateDidComplete:(KeyVerificationCoordinatorBridgePresenter *)coordinatorBridgePresenter otherUserId:(NSString * _Nonnull)otherUserId otherDeviceId:(NSString * _Nonnull)otherDeviceId
{
    MXCrypto *crypto = coordinatorBridgePresenter.session.crypto;
    if (!crypto.backup.hasPrivateKeyInCryptoStore || !crypto.backup.enabled)
    {
        NSLog(@"[AppDelegate][MXKeyVerification] requestAllPrivateKeys: Request key backup private keys");
        [crypto setOutgoingKeyRequestsEnabled:YES onComplete:nil];
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
}

#pragma mark - New request

- (void)registerNewRequestNotificationForSession:(MXSession*)session
{
    MXKeyVerificationManager *keyverificationManager = session.crypto.keyVerificationManager;
    
    if (!keyverificationManager)
    {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyVerificationNewRequestNotification:) name:MXKeyVerificationManagerNewRequestNotification object:keyverificationManager];
}

- (void)keyVerificationNewRequestNotification:(NSNotification *)notification
{
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)
    {
        return;
    }
    
    if (_masterTabBarController.authenticationInProgress)
    {
        NSLog(@"[AppDelegate][KeyVerification] keyVerificationNewRequestNotification: Postpone requests during the authentication process");
        
        // 10s is quite arbitrary
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self keyVerificationNewRequestNotification:notification];
        });
        return;
    }
    
    NSDictionary *userInfo = notification.userInfo;
    
    MXKeyVerificationRequest *keyVerificationRequest = userInfo[MXKeyVerificationManagerNotificationRequestKey];
    
    if ([keyVerificationRequest isKindOfClass:MXKeyVerificationByDMRequest.class])
    {
        MXKeyVerificationByDMRequest *keyVerificationByDMRequest = (MXKeyVerificationByDMRequest*)keyVerificationRequest;
        
        if (!keyVerificationByDMRequest.isFromMyUser && keyVerificationByDMRequest.state == MXKeyVerificationRequestStatePending)
        {
            MXKAccount *currentAccount = [MXKAccountManager sharedManager].activeAccounts.firstObject;
            MXSession *session = currentAccount.mxSession;
            MXRoom *room = [currentAccount.mxSession roomWithRoomId:keyVerificationByDMRequest.roomId];
            if (!room)
            {
                NSLog(@"[AppDelegate][KeyVerification] keyVerificationRequestDidChangeNotification: Unknown room");
                return;
            }
            
            NSString *sender = keyVerificationByDMRequest.otherUser;

            [room state:^(MXRoomState *roomState) {

                NSString *senderName = [roomState.members memberName:sender];
                
                [self presentNewKeyVerificationRequestAlertForSession:session senderName:senderName senderId:sender request:keyVerificationByDMRequest];
            }];
        }
    }
    else if ([keyVerificationRequest isKindOfClass:MXKeyVerificationByToDeviceRequest.class])
    {
        MXKeyVerificationByToDeviceRequest *keyVerificationByToDeviceRequest = (MXKeyVerificationByToDeviceRequest*)keyVerificationRequest;
        
        if (!keyVerificationByToDeviceRequest.isFromMyDevice
            && keyVerificationByToDeviceRequest.state == MXKeyVerificationRequestStatePending)
        {
            if (keyVerificationByToDeviceRequest.isFromMyUser)
            {
                // Self verification
                NSLog(@"[AppDelegate][KeyVerification] keyVerificationNewRequestNotification: Self verification from %@", keyVerificationByToDeviceRequest.otherDevice);
                
                if (!self.handleSelfVerificationRequest)
                {
                    NSLog(@"[AppDelegate][KeyVerification] keyVerificationNewRequestNotification: Self verification handled elsewhere");
                    return;
                }
                      
                NSString *myUserId = keyVerificationByToDeviceRequest.otherUser;
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
                NSLog(@"[AppDelegate][KeyVerification] keyVerificationNewRequestNotification: Device verification from other user %@:%@", keyVerificationByToDeviceRequest.otherUser, keyVerificationByToDeviceRequest.otherDevice);
                
                NSString *myUserId = keyVerificationByToDeviceRequest.to;
                NSString *userId = keyVerificationByToDeviceRequest.otherUser;
                MXKAccount *account = [[MXKAccountManager sharedManager] accountForUserId:myUserId];
                if (account)
                {
                    MXSession *session = account.mxSession;
                    MXUser *user = [session userWithUserId:userId];
                    
                    [self presentNewKeyVerificationRequestAlertForSession:session senderName:user.displayname senderId:user.userId request:keyVerificationRequest];
                }
            }
        }
        else
        {
            NSLog(@"[AppDelegate][KeyVerification] keyVerificationNewRequestNotification. Bad request state: %@", keyVerificationByToDeviceRequest);
        }
    }
}

- (void)presentNewKeyVerificationRequestAlertForSession:(MXSession*)session
                                             senderName:(NSString*)senderName
                                               senderId:(NSString*)senderId
                                                request:(MXKeyVerificationRequest*)keyVerificationRequest
{
    if (keyVerificationRequest.state != MXKeyVerificationRequestStatePending)
    {
        NSLog(@"[AppDelegate] presentNewKeyVerificationRequest: Request already accepted. Do not display it");
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
        NSLog(@"[AppDelegate] presentNewKeyVerificationRequest: Remove the alert for new sign in detected");
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

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"key_verification_tile_request_incoming_title", @"Vector", nil)
                                                                                             message:senderInfo
                                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"key_verification_tile_request_incoming_approval_accept", @"Vector", nil)
                                                                                           style:UIAlertActionStyleDefault
                                                                                         handler:^(UIAlertAction * action)
                                                                   {
                                                                       removeObserver();
                                                                       [self presentIncomingKeyVerificationRequest:keyVerificationRequest inSession:session];
                                                                   }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"key_verification_tile_request_incoming_approval_decline", @"Vector", nil)
                                                                                           style:UIAlertActionStyleDestructive
                                                                                         handler:^(UIAlertAction * action)
                                                                   {
                                                                       removeObserver();
                                                                       [keyVerificationRequest cancelWithCancelCode:MXTransactionCancelCode.user success:^{
                                                                           
                                                                       } failure:^(NSError * _Nonnull error) {
                                                                           NSLog(@"[AppDelegate][KeyVerification] Fail to cancel incoming key verification request with error: %@", error);
                                                                       }];
                                                                   }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"later", @"Vector", nil)
                                                                                           style:UIAlertActionStyleCancel
                                                                                         handler:^(UIAlertAction * action)
                                                                   {
                                                                       removeObserver();
                                                                   }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
    self.incomingKeyVerificationRequestAlertController = alertController;
    
    observer = [[NSNotificationCenter defaultCenter] addObserverForName:MXKeyVerificationRequestDidChangeNotification
                                                                 object:keyVerificationRequest
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(NSNotification * _Nonnull note)
                {
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
    MXCrossSigning *crossSigning = session.crypto.crossSigning;
    
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
             NSLog(@"[AppDelegate][NewSignIn] Fail to fetch devices");
         }];
     }];
}

- (void)presentNewSignInAlertForDevice:(MXDevice*)device inSession:(MXSession*)session
{
    NSLog(@"[AppDelegate] presentNewSignInAlertForDevice: %@", device.deviceId);
    
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
    
    NSString *alertMessage = [NSString stringWithFormat:NSLocalizedStringFromTable(@"device_verification_self_verify_alert_message", @"Vector", nil), deviceInfo];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"device_verification_self_verify_alert_title", @"Vector", nil)
                                                                   message:alertMessage
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"device_verification_self_verify_alert_validate_action", @"Vector", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
        self.userNewSignInAlertController = nil;
        [self presentSelfVerificationForOtherDeviceId:device.deviceId inSession:session];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"later", @"Vector", nil)
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
    MXCrossSigning *crossSigning = session.crypto.crossSigning;
    
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
               
        NSLog(@"[AppDelegate] registerDidChangeCrossSigningKeysNotificationForSession");
        
        if (self.userNewSignInAlertController)
        {
            NSLog(@"[AppDelegate] registerDidChangeCrossSigningKeysNotificationForSession: Hide NewSignInAlertController");
            
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
    NSLog(@"[AppDelegate][MXKeyVerification] presentCompleteSecurityForSession");
    
    BOOL presented = NO;
    if (!keyVerificationCoordinatorBridgePresenter.isPresenting)
    {
        keyVerificationCoordinatorBridgePresenter = [[KeyVerificationCoordinatorBridgePresenter alloc] initWithSession:mxSession];
        keyVerificationCoordinatorBridgePresenter.delegate = self;
        
        [keyVerificationCoordinatorBridgePresenter presentCompleteSecurityFrom:self.presentedViewController isNewSignIn:NO animated:YES];
        
        presented = YES;
    }
    else
    {
        NSLog(@"[AppDelegate][MXKeyVerification] presentCompleteSecurityForSession: Controller already presented.");
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
            
            NSString *alertMessage = [NSString stringWithFormat:NSLocalizedStringFromTable(@"gdpr_consent_not_given_alert_message", @"Vector", nil), homeServerName];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"settings_term_conditions", @"Vector", nil)                                        
                                                                           message:alertMessage
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"gdpr_consent_not_given_alert_review_now_action", @"Vector", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action) {
                                                        
                                                        typeof(weakSelf) strongSelf = weakSelf;
                                                        
                                                        if (strongSelf)
                                                        {
                                                            [strongSelf presentGDPRConsentFromViewController:self.presentedViewController consentURI:consentURI];
                                                        }
                                                    }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"later", @"Vector", nil)
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
    
    UIBarButtonItem *closeBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle mxk_localizedStringForKey:@"close"]
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

#pragma mark - Identity server service terms

// Observe identity server terms not signed notification
- (void)registerIdentityServiceTermsNotSignedNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleIdentityServiceTermsNotSignedNotification:) name:MXIdentityServiceTermsNotSignedNotification object:nil];
}

- (void)handleIdentityServiceTermsNotSignedNotification:(NSNotification*)notification
{
    NSLog(@"[AppDelegate] IS Terms: handleIdentityServiceTermsNotSignedNotification.");

    NSString *baseURL;
    NSString *accessToken;
    
    MXJSONModelSetString(baseURL, notification.userInfo[MXIdentityServiceNotificationIdentityServerKey]);
    MXJSONModelSetString(accessToken, notification.userInfo[MXIdentityServiceNotificationAccessTokenKey]);
    
    [self presentIdentityServerTermsWithBaseURL:baseURL andAccessToken:accessToken];
}

- (void)presentIdentityServerTermsWithBaseURL:(NSString*)baseURL andAccessToken:(NSString*)accessToken
{
    MXSession *mxSession = self.mxSessions.firstObject;
    
    if (!mxSession || !baseURL || !accessToken || self.serviceTermsModalCoordinatorBridgePresenter.isPresenting)
    {
        return;
    }
    
    ServiceTermsModalCoordinatorBridgePresenter *serviceTermsModalCoordinatorBridgePresenter = [[ServiceTermsModalCoordinatorBridgePresenter alloc] initWithSession:mxSession
                                                                                                                                                            baseUrl:baseURL
                                                                                                                                                        serviceType:MXServiceTypeIdentityService
                                                                                                                                                       outOfContext:YES
                                                                                                                                                        accessToken:accessToken];
    
    serviceTermsModalCoordinatorBridgePresenter.delegate = self;
    
    [serviceTermsModalCoordinatorBridgePresenter presentFrom:self.presentedViewController animated:YES];
    self.serviceTermsModalCoordinatorBridgePresenter = serviceTermsModalCoordinatorBridgePresenter;
}

- (void)serviceTermsModalCoordinatorBridgePresenterDelegateDidAccept:(ServiceTermsModalCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        
    }];
    self.serviceTermsModalCoordinatorBridgePresenter = nil;
}

- (void)serviceTermsModalCoordinatorBridgePresenterDelegateDidDecline:(ServiceTermsModalCoordinatorBridgePresenter *)coordinatorBridgePresenter session:(MXSession *)session
{
    NSLog(@"[AppDelegate] IS Terms: User has declined the use of the default IS.");

    // The user does not want to use the proposed IS.
    // Disable IS feature on user's account
    [session setIdentityServer:nil andAccessToken:nil];
    [session setAccountDataIdentityServer:nil success:^{
    } failure:^(NSError *error) {
        NSLog(@"[AppDelegate] IS Terms: Error: %@", error);
    }];

    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{

    }];
    self.serviceTermsModalCoordinatorBridgePresenter = nil;
}

- (void)serviceTermsModalCoordinatorBridgePresenterDelegateDidCancel:(ServiceTermsModalCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        
    }];
    self.serviceTermsModalCoordinatorBridgePresenter = nil;
}

#pragma mark - Settings

- (void)setupUserDefaults
{
    // Register "Riot-Defaults.plist" default values
    NSString* userDefaults = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UserDefaults"];
    NSString *defaultsPathFromApp = [[NSBundle mainBundle] pathForResource:userDefaults ofType:@"plist"];
    NSMutableDictionary *defaults = [[NSDictionary dictionaryWithContentsOfFile:defaultsPathFromApp] mutableCopy];
    
    //  add pusher ids, as they don't belong to plist anymore
    defaults[@"pushKitAppIdProd"] = BuildSettings.pushKitAppIdProd;
    defaults[@"pushKitAppIdDev"] = BuildSettings.pushKitAppIdDev;
    defaults[@"pusherAppIdProd"] = BuildSettings.pusherAppIdProd;
    defaults[@"pusherAppIdDev"] = BuildSettings.pusherAppIdDev;
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    if (!RiotSettings.shared.isUserDefaultsMigrated)
    {
        [RiotSettings.shared migrate];
    }
    
    // Now use RiotSettings and NSUserDefaults to store `showDecryptedContentInNotifications` setting option
    // Migrate this information from main MXKAccount to RiotSettings, if value is not in UserDefaults
    
    if (!RiotSettings.shared.isShowDecryptedContentInNotificationsHasBeenSetOnce)
    {
        MXKAccount *currentAccount = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        RiotSettings.shared.showDecryptedContentInNotifications = currentAccount.showDecryptedContentInNotifications;
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
                [self showAlertWithTitle:[NSBundle mxk_localizedStringForKey:@"error"] message:NSLocalizedStringFromTable(@"room_message_unable_open_link_error_message", @"Vector", nil)];
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
    [coordinatorBridgePresenter dismiss];
    self.setPinCoordinatorBridgePresenter = nil;
    [self afterAppUnlockedByPin:[UIApplication sharedApplication]];
}

- (void)setPinCoordinatorBridgePresenterDelegateDidCompleteWithReset:(SetPinCoordinatorBridgePresenter *)coordinatorBridgePresenter dueToTooManyErrors:(BOOL)dueToTooManyErrors
{
    if (dueToTooManyErrors)
    {
        [self showAlertWithTitle:nil message:NSLocalizedStringFromTable(@"pin_protection_kick_user_alert_message", @"Vector", nil)];
        [self logoutWithConfirmation:NO completion:nil];
    }
    else
    {
        [coordinatorBridgePresenter dismiss];
        self.setPinCoordinatorBridgePresenter = nil;
        [self logoutWithConfirmation:NO completion:nil];
    }
}

#pragma mark - CallPresenterDelegate

- (BOOL)callPresenter:(CallPresenter *)presenter shouldHandleNewCall:(MXCall *)call
{
    //  Ignore the call if a call is already in progress
    return _jitsiViewController == nil;
}

- (void)callPresenter:(CallPresenter *)presenter presentCallViewController:(CallViewController *)viewController completion:(void (^)(void))completion
{
    if (@available(iOS 13.0, *))
    {
        viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    
    [self presentViewController:viewController animated:YES completion:completion];
}

- (void)callPresenter:(CallPresenter *)presenter dismissCallViewController:(CallViewController *)viewController completion:(void (^)(void))completion
{
    // Check whether the call view controller is actually presented
    if (viewController.presentingViewController)
    {
        [viewController dismissViewControllerAnimated:YES completion:^{
            
            if (viewController.shouldPromptForStunServerFallback)
            {
                [self promptForStunServerFallback];
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

- (void)callPresenter:(CallPresenter *)presenter presentCallBarFor:(CallViewController *)activeCallViewController numberOfPausedCalls:(NSUInteger)numberOfPausedCalls completion:(void (^)(void))completion
{
    NSString *btnTitle;
    
    if (activeCallViewController)
    {
        if (numberOfPausedCalls == 0)
        {
            //  only one active
            btnTitle = [NSString stringWithFormat:NSLocalizedStringFromTable(@"callbar_only_single_active", @"Vector", nil), activeCallViewController.callStatusLabel.text];
        }
        else if (numberOfPausedCalls == 1)
        {
            //  one active and one paused
            btnTitle = [NSString stringWithFormat:NSLocalizedStringFromTable(@"callbar_active_and_single_paused", @"Vector", nil), activeCallViewController.callStatusLabel.text];
        }
        else
        {
            //  one active and multiple paused
            btnTitle = [NSString stringWithFormat:NSLocalizedStringFromTable(@"callbar_active_and_multiple_paused", @"Vector", nil), activeCallViewController.callStatusLabel.text, @(numberOfPausedCalls)];
        }
    }
    else
    {
        //  no active calls
        if (numberOfPausedCalls == 1)
        {
            btnTitle = NSLocalizedStringFromTable(@"callbar_only_single_paused", @"Vector", nil);
        }
        else
        {
            btnTitle = [NSString stringWithFormat:NSLocalizedStringFromTable(@"callbar_only_multiple_paused", @"Vector", nil), @(numberOfPausedCalls)];
        }
    }
    
    [self updateCallStatusBar:btnTitle];
    
    if (completion)
    {
        completion();
    }
}

- (void)callPresenter:(CallPresenter *)presenter dismissCallBar:(void (^)(void))completion
{
    [self removeCallStatusBar];
    
    if (completion)
    {
        completion();
    }
}

- (void)callPresenter:(CallPresenter *)presenter enterPipForCallViewController:(CallViewController *)viewController completion:(void (^)(void))completion
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

- (void)callPresenter:(CallPresenter *)presenter exitPipForCallViewController:(CallViewController *)viewController completion:(void (^)(void))completion
{
    if (@available(iOS 13.0, *))
    {
        viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    
    [self presentViewController:viewController animated:YES completion:completion];
}

#pragma mark - CallBarDelegate

- (void)callBarDidTapReturnButton:(CallBar *)callBar
{
    if ([_callPresenter callStatusBarButtonTapped])
    {
        return;
    }
    else if (_jitsiViewController)
    {
        [self presentJitsiViewController:nil];
    }
}
    
#pragma mark - Authentication

- (BOOL)continueSSOLoginWithToken:(NSString*)loginToken txnId:(NSString*)txnId
{
    AuthenticationViewController *authVC = self.masterTabBarController.authViewController;
    
    if (!authVC)
    {
        NSLog(@"[AppDelegate] Fail to continue SSO login");
        return NO;
    }
    
    return [authVC continueSSOLoginWithToken:loginToken txnId:txnId];
}

@end
