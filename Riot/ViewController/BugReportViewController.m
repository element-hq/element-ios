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

#import "AppDelegate.h"

#import "GBDeviceInfo_iOS.h"

@interface BugReportViewController ()
{
    MXBugReportRestClient *bugReportRestClient;

    // The temporary file used to store the screenshot
    NSURL *screenShotFile;
    
    // Observe kRiotDesignValuesDidChangeThemeNotification to handle user interface theme change.
    id kRiotDesignValuesDidChangeThemeNotificationObserver;
}

@property (nonatomic) BOOL sendLogs;
@property (nonatomic) BOOL sendScreenshot;

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

    _logsDescriptionLabel.text = NSLocalizedStringFromTable(@"bug_report_logs_description", @"Vector", nil);
    _sendLogsLabel.text = NSLocalizedStringFromTable(@"bug_report_send_logs", @"Vector", nil);
    _sendScreenshotLabel.text = NSLocalizedStringFromTable(@"bug_report_send_screenshot", @"Vector", nil);

    _containerView.layer.cornerRadius = 20;

    _bugReportDescriptionTextView.layer.borderWidth = 1.0f;
    _bugReportDescriptionTextView.text = nil;
    _bugReportDescriptionTextView.delegate = self;

    if (_reportCrash)
    {
        _titleLabel.text = NSLocalizedStringFromTable(@"bug_crash_report_title", @"Vector", nil);
        _descriptionLabel.text = NSLocalizedStringFromTable(@"bug_crash_report_description", @"Vector", nil);
    }
    else
    {
        _titleLabel.text = NSLocalizedStringFromTable(@"bug_report_title", @"Vector", nil);
        _descriptionLabel.text = NSLocalizedStringFromTable(@"bug_report_description", @"Vector", nil);
    }
    
    [_cancelButton setTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] forState:UIControlStateNormal];
    [_cancelButton setTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] forState:UIControlStateHighlighted];
    [_sendButton setTitle:NSLocalizedStringFromTable(@"bug_report_send", @"Vector", nil) forState:UIControlStateNormal];
    [_sendButton setTitle:NSLocalizedStringFromTable(@"bug_report_send", @"Vector", nil) forState:UIControlStateHighlighted];

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
    kRiotDesignValuesDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kRiotDesignValuesDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    self.defaultBarTintColor = kRiotSecondaryBgColor;
    self.barTitleColor = kRiotPrimaryTextColor;
    self.activityIndicator.backgroundColor = kRiotOverlayColor;
    
    self.overlayView.backgroundColor = kRiotOverlayColor;
    self.overlayView.alpha = 1.0;
    
    self.containerView.backgroundColor = kRiotPrimaryBgColor;
    self.sendingContainer.backgroundColor = kRiotPrimaryBgColor;
    
    self.bugReportDescriptionTextView.keyboardAppearance = kRiotKeyboard;
    
    self.titleLabel.textColor = kRiotPrimaryTextColor;
    self.sendingLabel.textColor = kRiotPrimaryTextColor;
    self.descriptionLabel.textColor = kRiotPrimaryTextColor;
    self.bugReportDescriptionTextView.textColor = kRiotPrimaryTextColor;
    self.bugReportDescriptionTextView.tintColor = kRiotColorGreen;
    self.logsDescriptionLabel.textColor = kRiotPrimaryTextColor;
    self.sendLogsLabel.textColor = kRiotPrimaryTextColor;
    self.sendScreenshotLabel.textColor = kRiotPrimaryTextColor;
    
    self.sendButton.tintColor = kRiotColorGreen;
    self.cancelButton.tintColor = kRiotColorGreen;
    
    _bugReportDescriptionTextView.layer.borderColor = kRiotSecondaryBgColor.CGColor;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return kRiotDesignStatusBarStyle;
}

- (void)destroy
{
    if (kRiotDesignValuesDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kRiotDesignValuesDidChangeThemeNotificationObserver];
        kRiotDesignValuesDidChangeThemeNotificationObserver = nil;
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
        _sendLogsButtonImage.image = [UIImage imageNamed:@"selection_tick"];
    }
    else
    {
        _sendLogsButtonImage.image = [UIImage imageNamed:@"selection_untick"];
    }
}

- (void)setSendScreenshot:(BOOL)sendScreenshot
{
    _sendScreenshot = sendScreenshot;
    if (_sendScreenshot)
    {
        _sendScreenshotButtonImage.image = [UIImage imageNamed:@"selection_tick"];
    }
    else
    {
        _sendScreenshotButtonImage.image = [UIImage imageNamed:@"selection_untick"];
    }
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
    _sendButton.hidden = YES;
    _sendingContainer.hidden = NO;

    // Setup data to send
    NSString *url = [[NSUserDefaults standardUserDefaults] objectForKey:@"bugReportEndpointUrl"];
    bugReportRestClient = [[MXBugReportRestClient alloc] initWithBugReportEndpoint:url];

    // App info
    bugReportRestClient.appName = [[NSUserDefaults standardUserDefaults] objectForKey:@"bugReportApp"]; // Use the name allocated by the bug report server
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
        if ([build isEqualToString:NSLocalizedStringFromTable(@"settings_config_no_build_info", @"Vector", nil)])
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

    // Submit
    [bugReportRestClient sendBugReport:bugReportDescription sendLogs:_sendLogs sendCrashLog:_reportCrash sendFiles:files attachGitHubLabels:gitHubLabels progress:^(MXBugReportState state, NSProgress *progress) {

        switch (state)
        {
            case MXBugReportStateProgressZipping:
                _sendingLabel.text = NSLocalizedStringFromTable(@"bug_report_progress_zipping", @"Vector", nil);
                break;

            case MXBugReportStateProgressUploading:
                _sendingLabel.text = NSLocalizedStringFromTable(@"bug_report_progress_uploading", @"Vector", nil);
                break;

            default:
                break;
        }

        _sendingProgress.progress = progress.fractionCompleted;

    } success:^{

        bugReportRestClient = nil;

        if (_reportCrash)
        {
            // Erase the crash log
            [MXLogger deleteCrashLog];
        }

        [self dismissViewControllerAnimated:YES completion:nil];

    } failure:^(NSError *error) {

        bugReportRestClient = nil;

        [[AppDelegate theDelegate] showErrorAsAlert:error];

        _sendButton.hidden = NO;
        _sendingContainer.hidden = YES;
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

        _sendButton.hidden = NO;
        _sendingContainer.hidden = YES;
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

@end
