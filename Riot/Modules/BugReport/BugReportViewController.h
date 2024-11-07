/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
