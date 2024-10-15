/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

/**
 'CallViewController' instance displays a call. Only one matrix session is supported by this view controller.
 */
@interface CallViewController : MXKCallViewController

@property (weak, nonatomic) IBOutlet UIButton *chatButton;

@property (weak, nonatomic) IBOutlet UIView *callControlsBackgroundView;

@property (unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *callerImageViewWidthConstraint;

//  Effect views
@property (weak, nonatomic) IBOutlet MXKImageView *blurredCallerImageView;

// At the end of call, this flag indicates if the prompt to use the fallback should be displayed
@property (nonatomic) BOOL shouldPromptForStunServerFallback;

@end
