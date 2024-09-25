/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
    
    [_cancelButton setTitle:[VectorL10n cancel] forState:UIControlStateNormal];
    [_cancelButton setTitle:[VectorL10n cancel] forState:UIControlStateHighlighted];
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

    bugReportRestClient = [MXBugReportRestClient vc_bugReportRestClientWithAppName:BuildSettings.bugReportApplicationId];
    
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
    
    NSMutableString *bugReportDescription = [NSMutableString stringWithString:_bugReportDescriptionTextView.text];
    
    // starting a background task to have a bit of extra time in case of user forgets about the report and sends the app to background
    __block UIBackgroundTaskIdentifier operationBackgroundId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:operationBackgroundId];
            operationBackgroundId = UIBackgroundTaskInvalid;
        }];
    
    [bugReportRestClient vc_sendBugReportWithDescription:bugReportDescription
                                                sendLogs:_sendLogs
                                            sendCrashLog:_reportCrash
                                               sendFiles:files
                                        additionalLabels:nil
                                            customFields:nil
                                                progress:^(MXBugReportState state, NSProgress *progress) {
        
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

    } success:^(NSString *reportUrl){

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
