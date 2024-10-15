/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <MatrixSDK/MatrixSDK.h>

#import "MXKView.h"

@interface MXKEventDetailsView : MXKView

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *redactButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (instancetype)initWithEvent:(MXEvent*)event andMatrixSession:(MXSession*)session;

@end

