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
}

@property (nonatomic) BOOL sendLogs;
@property (nonatomic) BOOL sendScreenshot;

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
    self.modalPresentationStyle = UIModalPresentationOverCurrentContext;

    [viewController presentViewController:self animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSLog(@"%@", _screenshot);

    _logsDescriptionLabel.text = NSLocalizedStringFromTable(@"bug_report_logs_description", @"Vector", nil);
    _sendLogsLabel.text = NSLocalizedStringFromTable(@"bug_report_send_logs", @"Vector", nil);
    _sendScreenshotLabel.text = NSLocalizedStringFromTable(@"bug_report_send_screenshot", @"Vector", nil);

    _containerView.layer.cornerRadius = 20;

    _bugReportDescriptionTextView.layer.borderWidth = 1.0f;
    _bugReportDescriptionTextView.layer.borderColor = kRiotColorLightGrey.CGColor;
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

        // Allow to send empty description for crash report but not for bug report
        _sendButton.enabled = NO;
    }

    _sendingContainer.hidden = YES;

    self.sendLogs = YES;
    self.sendScreenshot = YES;

    // Hide the screenshot button if there is no screenshot
    // if (!_screenshot)    // TODO: always hide it becayse screenshot is not yet supported by the bug report API
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
    //bugReportRestClient = [[MXBugReportRestClient alloc] initWithBugReportEndpoint:@"http://192.168.2.9:9110"];
    //bugReportRestClient = [[MXBugReportRestClient alloc] initWithBugReportEndpoint:@"http://192.168.0.4:9110"];
    bugReportRestClient = [[MXBugReportRestClient alloc] initWithBugReportEndpoint:@"http://172.20.10.2:9110"];


    // App info
    bugReportRestClient.appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]; // NO ?
    bugReportRestClient.version = [AppDelegate theDelegate].appVersion;
    bugReportRestClient.build = [AppDelegate theDelegate].build;

    // Device info
    bugReportRestClient.deviceModel = [GBDeviceInfo deviceInfo].modelString;
    bugReportRestClient.deviceOS = [NSString stringWithFormat:@"%@ %@", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]];

    // Submit
    [bugReportRestClient sendBugReport:_bugReportDescriptionTextView.text sendLogs:_sendLogs sendCrashLog:_reportCrash progress:^(MXBugReportState state, NSProgress *progress) {

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
