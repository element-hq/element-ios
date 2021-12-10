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

#import <UIKit/UIKit.h>

#import "MatrixKit.h"

@interface BugReportViewController : MXKViewController <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewBottomConstraint;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIView *bugDescriptionContainer;

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UITextView *bugReportDescriptionTextView;
@property (weak, nonatomic) IBOutlet UILabel *logsDescriptionLabel;

@property (weak, nonatomic) IBOutlet UIView *sendLogsContainer;
@property (weak, nonatomic) IBOutlet UILabel *sendLogsLabel;
@property (weak, nonatomic) IBOutlet UIImageView *sendLogsButtonImage;

@property (weak, nonatomic) IBOutlet UIView *sendScreenshotContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sendScreenshotContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet UILabel *sendScreenshotLabel;
@property (weak, nonatomic) IBOutlet UIImageView *sendScreenshotButtonImage;

@property (weak, nonatomic) IBOutlet UIView *sendingContainer;
@property (weak, nonatomic) IBOutlet UILabel *sendingLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *sendingProgress;

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;

@property (weak, nonatomic) IBOutlet UIButton *backgroundButton;

+ (instancetype)bugReportViewController;

- (void)showInViewController:(UIViewController*)viewController;

/**
 The screenshot to send with the bug report.
 */
@property (nonatomic) UIImage *screenshot;

/**
 Option to report a crash.
 The crash log will sent in the report.
 */
@property (nonatomic) BOOL reportCrash;

@end
