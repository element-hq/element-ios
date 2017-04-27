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

@interface BugReportViewController ()

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

    _containerView.layer.cornerRadius = 20;

    _bugReportDescriptionTextView.layer.borderWidth = 1.0f;
    _bugReportDescriptionTextView.layer.borderColor = [UIColor redColor].CGColor;
}

- (void)showInViewController:(UIViewController *)viewController
{
    self.providesPresentationContextTransitionStyle = YES;
    self.definesPresentationContext = YES;
    self.modalPresentationStyle = UIModalPresentationOverCurrentContext;

    [viewController presentViewController:self animated:YES completion:nil];
}

#pragma mark - User actions

- (IBAction)onSendButtonPress:(id)sender
{

}

- (IBAction)onCancelButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
