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

- (void)viewDidLoad
{
    [super viewDidLoad];

    _titleLabel.text = NSLocalizedStringFromTable(@"bug_report_title", @"Vector", nil);
    _descriptionLabel.text = NSLocalizedStringFromTable(@"bug_report_description", @"Vector", nil);
    _logsDescriptionLabel.text = NSLocalizedStringFromTable(@"bug_report_logs_description", @"Vector", nil);
    _sendLogsLabel.text = NSLocalizedStringFromTable(@"bug_report_send_logs", @"Vector", nil);
    _sendScreenshotLabel.text = NSLocalizedStringFromTable(@"bug_report_send_screenshot", @"Vector", nil);

    _containerView.layer.cornerRadius = 20;

    _bugReportDescriptionTextView.layer.borderWidth = 1.0f;
    _bugReportDescriptionTextView.layer.borderColor = kRiotColorLightGrey.CGColor;
    _bugReportDescriptionTextView.text = nil;
    _bugReportDescriptionTextView.delegate = self;

    _sendButton.enabled = NO;

    // TODO: Screenshot is not yet supported by the bug report API
    _sendScreenshotContainer.hidden = YES;
    _sendScreenshotContainerHeightConstraint.constant = 0;

    // Show a Done button to hide the keyboard
    UIToolbar *viewForDoneButtonOnKeyboard = [[UIToolbar alloc] init];
    [viewForDoneButtonOnKeyboard sizeToFit];

    UIBarButtonItem *btnDoneOnKeyboard = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(onKeyboardDoneButtonPressed:)];

    viewForDoneButtonOnKeyboard.items = @[btnDoneOnKeyboard];

    _bugReportDescriptionTextView.inputAccessoryView = viewForDoneButtonOnKeyboard;
}

- (void)showInViewController:(UIViewController *)viewController
{
    self.providesPresentationContextTransitionStyle = YES;
    self.definesPresentationContext = YES;
    self.modalPresentationStyle = UIModalPresentationOverCurrentContext;

    [viewController presentViewController:self animated:YES completion:nil];
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
    _bugDescriptionContainer.hidden = YES;

    // Setup data to send
    bugReportRestClient = [[MXBugReportRestClient alloc] initWithBugReportEndpoint:@"http://192.168.2.9:9110"];

    // App info
    bugReportRestClient.appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]; // NO ?
    bugReportRestClient.version = [AppDelegate theDelegate].appVersion;
    bugReportRestClient.build = [AppDelegate theDelegate].build;

    // Device info
    bugReportRestClient.deviceModel = [GBDeviceInfo deviceInfo].modelString;
    bugReportRestClient.deviceOS = [NSString stringWithFormat:@"%@ %@", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]];

    // Submit
    [bugReportRestClient sendBugReport:_bugReportDescriptionTextView.text sendLogs:YES progress:^(MXBugReportState state, NSProgress *progress) {



    } success:^{

        bugReportRestClient = nil;
        [self dismissViewControllerAnimated:YES completion:nil];

    } failure:^(NSError *error) {

        bugReportRestClient = nil;

        [[AppDelegate theDelegate] showErrorAsAlert:error];

        _sendButton.hidden = NO;
        _bugDescriptionContainer.hidden = NO;
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
        _bugDescriptionContainer.hidden = NO;
    }
    else
    {
        // Else, lease the bug report screen
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)onKeyboardDoneButtonPressed:(id)sender
{
    [_bugReportDescriptionTextView resignFirstResponder];
}

@end
