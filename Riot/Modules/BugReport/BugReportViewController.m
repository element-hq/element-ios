/*
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

#import "BugReportViewController.h"

#import "GeneratedInterface-Swift.h"

#import "GBDeviceInfo_iOS.h"

@interface BugReportViewController ()
{
    MXBugReportRestClient *bugReportRestClient;

    // The temporary file used to store the screenshot
    NSURL *screenShotFile;
    
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;
}

@property (nonatomic) BOOL sendLogs;
@property (nonatomic) BOOL sendScreenshot;
@property (nonatomic) BOOL isSendingLogs;

@property (weak, nonatomic) IBOutlet UIView *overlayView;

@end

@implementation BugReportViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([BugReportViewController class])
                          bundle:[NSBundle bundleForClass:[BugReportViewController class]]];
}

+ (instancetype)bugReportViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([BugReportViewController class])
                                          bundle:[NSBundle bundleForClass:[BugReportViewController class]]];
}

#pragma mark -

- (void)showInViewController:(UIViewController *)viewController
{
    self.providesPresentationContextTransitionStyle = YES;
    self.definesPresentationContext = YES;
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

    [viewController presentViewController:self animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _logsDescriptionLabel.text = [VectorL10n bugReportLogsDescription];
    _sendLogsLabel.text = [VectorL10n bugReportSendLogs];
    _sendScreenshotLabel.text = [VectorL10n bugReportSendScreenshot];

    _containerView.layer.cornerRadius = 20;

    _bugReportDescriptionTextView.layer.borderWidth = 1.0f;
    _bugReportDescriptionTextView.text = nil;
    _bugReportDescriptionTextView.delegate = self;

    if (_reportCrash)
    {
        _titleLabel.text = [VectorL10n bugCrashReportTitle];
        _descriptionLabel.text = [VectorL10n bugCrashReportDescription];
    }
    else
    {
        _titleLabel.text = [VectorL10n bugReportTitle];
        _descriptionLabel.text = [VectorL10n bugReportDescription];
    }
    
    [_cancelButton setTitle:[MatrixKitL10n cancel] forState:UIControlStateNormal];
    [_cancelButton setTitle:[MatrixKitL10n cancel] forState:UIControlStateHighlighted];
    [_sendButton setTitle:[VectorL10n bugReportSend] forState:UIControlStateNormal];
    [_sendButton setTitle:[VectorL10n bugReportSend] forState:UIControlStateHighlighted];
    [_backgroundButton setTitle:[VectorL10n bugReportBackgroundMode] forState:UIControlStateNormal];
    [_backgroundButton setTitle:[VectorL10n bugReportBackgroundMode] forState:UIControlStateHighlighted];

    // Do not send empty report
    _sendButton.enabled = NO;;
    
    _sendingContainer.hidden = YES;

    self.sendLogs = YES;
    self.sendScreenshot = YES;

    // Hide the screenshot button if there is no screenshot
    if (!_screenshot)
    {
        _sendScreenshotContainer.hidden = YES;
        _sendScreenshotContainerHeightConstraint.constant = 0;
    }

    // Listen to sendLogs tap
    UITapGestureRecognizer *sendLogsTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSendLogsTap:)];
    [sendLogsTapGesture setNumberOfTouchesRequired:1];
    [_sendLogsContainer addGestureRecognizer:sendLogsTapGesture];
    _sendLogsContainer.userInteractionEnabled = YES;

    // Listen to sendScreenshot tap
    UITapGestureRecognizer *sendScreenshotTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSendScreenshotTap:)];
    [sendScreenshotTapGesture setNumberOfTouchesRequired:1];
    [_sendScreenshotContainer addGestureRecognizer:sendScreenshotTapGesture];
    _sendScreenshotContainer.userInteractionEnabled = YES;

    // Add an accessory view in order to retrieve keyboard view
    _bugReportDescriptionTextView.inputAccessoryView = [[UIView alloc] initWithFrame:CGRectZero];

    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
    
    UIGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundViewTapped)];
    [self.view addGestureRecognizer:recognizer];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    self.overlayView.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    self.overlayView.alpha = 1.0;
    
    self.containerView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.sendingContainer.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    self.bugReportDescriptionTextView.keyboardAppearance = ThemeService.shared.theme.keyboardAppearance;
    
    self.titleLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.sendingLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.descriptionLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.bugReportDescriptionTextView.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.bugReportDescriptionTextView.tintColor = ThemeService.shared.theme.tintColor;
    self.logsDescriptionLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.sendLogsLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.sendScreenshotLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    
    self.sendButton.tintColor = ThemeService.shared.theme.tintColor;
    self.cancelButton.tintColor = ThemeService.shared.theme.tintColor;
    self.backgroundButton.tintColor = ThemeService.shared.theme.tintColor;
    
    _bugReportDescriptionTextView.layer.borderColor = ThemeService.shared.theme.headerBackgroundColor.CGColor;
    
    self.sendLogsButtonImage.tintColor = ThemeService.shared.theme.tintColor;
    self.sendScreenshotButtonImage.tintColor = ThemeService.shared.theme.tintColor;

    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (void)destroy
{
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
    
    [super destroy];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [super dismissViewControllerAnimated:flag completion:completion];
    
    [self destroy];
}

- (void)dealloc
{
    _bugReportDescriptionTextView.inputAccessoryView = nil;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self dismissKeyboard];

    if (screenShotFile)
    {
        [[NSFileManager defaultManager] removeItemAtURL:screenShotFile error:nil];
        screenShotFile = nil;
    }
}

- (void)setSendLogs:(BOOL)sendLogs
{
    _sendLogs = sendLogs;
    if (_sendLogs)
    {
        _sendLogsButtonImage.image = AssetImages.selectionTick.image;
    }
    else
    {
        _sendLogsButtonImage.image = AssetImages.selectionUntick.image;
    }
}

- (void)setSendScreenshot:(BOOL)sendScreenshot
{
    _sendScreenshot = sendScreenshot;
    if (_sendScreenshot)
    {
        _sendScreenshotButtonImage.image = AssetImages.selectionTick.image;
    }
    else
    {
        _sendScreenshotButtonImage.image = AssetImages.selectionUntick.image;
    }
}

- (void)setIsSendingLogs:(BOOL)isSendingLogs
{
    _isSendingLogs = isSendingLogs;
    
    _sendButton.hidden = isSendingLogs;
    _sendingContainer.hidden = !isSendingLogs;
    _backgroundButton.hidden = !isSendingLogs;
}

#pragma mark - MXKViewController
- (void)dismissKeyboard
{
    // Hide the keyboard
    [_bugReportDescriptionTextView resignFirstResponder];
}

- (void)onKeyboardShowAnimationComplete
{
    self.keyboardView = _bugReportDescriptionTextView.inputAccessoryView.superview;
}

-(void)setKeyboardHeight:(CGFloat)keyboardHeight
{
    // In portrait in 6/7 and 6+/7+, make the height of the popup smaller to be able to
    // display Cancel and Send buttons.
    // Do nothing in landscape or in 5 in portrait and in landscape. There will be not enough
    // room to display bugReportDescriptionTextView.
    if (self.view.frame.size.height > 568)
    {
        self.scrollViewBottomConstraint.constant = keyboardHeight;
    }
    else
    {
        self.scrollViewBottomConstraint.constant = 0;
    }

    [self.view layoutIfNeeded];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    _sendButton.enabled = (_bugReportDescriptionTextView.text.length != 0);
}

#pragma mark - User actions

- (IBAction)onSendButtonPress:(id)sender
{
    self.isSendingLogs = YES;

    // Setup data to send
    bugReportRestClient = [[MXBugReportRestClient alloc] initWithBugReportEndpoint:BuildSettings.bugReportEndpointUrlString];

    // App info
    bugReportRestClient.appName = BuildSettings.bugReportApplicationId;
    bugReportRestClient.version = [AppDelegate theDelegate].appVersion;
    bugReportRestClient.build = [AppDelegate theDelegate].build;

    // Device info
    bugReportRestClient.deviceModel = [GBDeviceInfo deviceInfo].modelString;
    bugReportRestClient.deviceOS = [NSString stringWithFormat:@"%@ %@", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]];

    // User info (TODO: handle multi-account and find a way to expose them in rageshake API)
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    MXKAccount *mainAccount = [MXKAccountManager sharedManager].accounts.firstObject;
    if (mainAccount.mxSession.myUser.userId)
    {
        userInfo[@"user_id"] = mainAccount.mxSession.myUser.userId;
    }
    if (mainAccount.mxSession.matrixRestClient.credentials.deviceId)
    {
        userInfo[@"device_id"] = mainAccount.mxSession.matrixRestClient.credentials.deviceId;
    }

    userInfo[@"locale"] = [NSLocale preferredLanguages][0];
    userInfo[@"default_app_language"] = [[NSBundle mainBundle] preferredLocalizations][0]; // The language chosen by the OS
    userInfo[@"app_language"] = [NSBundle mxk_language] ? [NSBundle mxk_language] : userInfo[@"default_app_language"]; // The language chosen by the user

    // Application settings
    userInfo[@"lazy_loading"] = [MXKAppSettings standardAppSettings].syncWithLazyLoadOfRoomMembers ? @"ON" : @"OFF";

    NSDate *currentDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    userInfo[@"local_time"] = [dateFormatter stringFromDate:currentDate];

    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    userInfo[@"utc_time"] = [dateFormatter stringFromDate:currentDate];

    bugReportRestClient.others = userInfo;

    // Screenshot
    NSArray<NSURL*> *files;
    if (_screenshot && _sendScreenshot)
    {
        // Store the screenshot into a temporary file
        NSData *screenShotData = UIImagePNGRepresentation(_screenshot);
        screenShotFile = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"screenshot.png"]];
        [screenShotData writeToURL:screenShotFile atomically:YES];

        files = @[screenShotFile];
    }

    // Prepare labels to attach to the GitHub issue
    NSMutableArray<NSString*> *gitHubLabels = [NSMutableArray array];
    if (_reportCrash)
    {
        // Label the GH issue as "crash"
        [gitHubLabels addObject:@"crash"];
    }

    // Add a Github label giving information about the version
    if (bugReportRestClient.version && bugReportRestClient.build)
    {
        NSString *build = bugReportRestClient.build;
        NSString *versionLabel = bugReportRestClient.version;

        // If this is not the app store version, be more accurate on the build origin
        if ([build isEqualToString:[VectorL10n settingsConfigNoBuildInfo]])
        {
            // This is a debug session from Xcode
            versionLabel = [versionLabel stringByAppendingString:@"-debug"];
        }
        else if (build && ![build containsString:@"master"])
        {
            // This is a Jenkins build. Add the branch and the build number
            NSString *buildString = [build stringByReplacingOccurrencesOfString:@" " withString:@"-"];
            versionLabel = [[versionLabel stringByAppendingString:@"-"] stringByAppendingString:buildString];
        }

        [gitHubLabels addObject:versionLabel];
    }

    NSMutableString *bugReportDescription = [NSMutableString stringWithString:_bugReportDescriptionTextView.text];

    if (_reportCrash)
    {
        // Append the crash dump to the user description in order to ease triaging of GH issues
        NSString *crashLogFile = [MXLogger crashLog];
        NSString *crashLog =  [NSString stringWithContentsOfFile:crashLogFile encoding:NSUTF8StringEncoding error:nil];
        [bugReportDescription appendFormat:@"\n\n\n--------------------------------------------------------------------------------\n\n%@", crashLog];
    }

    // starting a background task to have a bit of extra time in case of user forgets about the report and sends the app to background
    __block UIBackgroundTaskIdentifier operationBackgroundId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:operationBackgroundId];
            operationBackgroundId = UIBackgroundTaskInvalid;
        }];
    
    // Submit
    [bugReportRestClient sendBugReport:bugReportDescription sendLogs:_sendLogs sendCrashLog:_reportCrash sendFiles:files attachGitHubLabels:gitHubLabels progress:^(MXBugReportState state, NSProgress *progress) {

        switch (state)
        {
            case MXBugReportStateProgressZipping:
                self.sendingLabel.text = [VectorL10n bugReportProgressZipping];
                break;

            case MXBugReportStateProgressUploading:
                self.sendingLabel.text = [VectorL10n bugReportProgressUploading];
                break;

            default:
                break;
        }

        self.sendingProgress.progress = progress.fractionCompleted;

    } success:^{

        self->bugReportRestClient = nil;

        if (self.reportCrash)
        {
            // Erase the crash log
            [MXLogger deleteCrashLog];
        }

        [self dismissViewControllerAnimated:YES completion:nil];
        
        if (operationBackgroundId != UIBackgroundTaskInvalid)
        {
            [[UIApplication sharedApplication] endBackgroundTask:operationBackgroundId];
            operationBackgroundId = UIBackgroundTaskInvalid;
        }

    } failure:^(NSError *error) {

        if (self.presentingViewController)
        {
            self->bugReportRestClient = nil;

            [[AppDelegate theDelegate] showErrorAsAlert:error];

            self.isSendingLogs = NO;
        }
        else
        {
            [[[UIApplication sharedApplication].windows firstObject].rootViewController presentViewController:self animated:YES completion:^{
                self->bugReportRestClient = nil;

                [[AppDelegate theDelegate] showErrorAsAlert:error];

                self.isSendingLogs = NO;
            }];
        }
        
        if (operationBackgroundId != UIBackgroundTaskInvalid)
        {
            [[UIApplication sharedApplication] endBackgroundTask:operationBackgroundId];
            operationBackgroundId = UIBackgroundTaskInvalid;
        }
    }];
}

- (IBAction)onCancelButtonPressed:(id)sender
{
    if (bugReportRestClient)
    {
        // If the submission is in progress, cancel the sending and come back
        // to the bug report screen
        [bugReportRestClient cancel];
        bugReportRestClient = nil;

        self.isSendingLogs = NO;
    }
    else
    {
        if (_reportCrash)
        {
            // Erase the crash log
            [MXLogger deleteCrashLog];
        }

        // Else, lease the bug report screen
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)onSendLogsTap:(id)sender
{
    self.sendLogs = !self.sendLogs;
}

- (IBAction)onSendScreenshotTap:(id)sender
{
    self.sendScreenshot = !self.sendScreenshot;
}

- (IBAction)onBackgroundTap:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)backgroundViewTapped
{
    // Dismiss keyboard if user taps on background view: https://github.com/vector-im/element-ios/issues/3819
    [self.bugReportDescriptionTextView resignFirstResponder];
}

@end
