/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewHeaderFooterView.h"

/**
 'MXKTableViewHeaderFooterWithLabel' inherits 'MXKTableViewHeaderFooterView' class.
 It constains a 'UILabel' vertically centered in which the dymanic fonts is enabled.
 The height of this header is dynamically adapted to its content.
 */
@interface MXKTableViewHeaderFooterWithLabel : MXKTableViewHeaderFooterView

@property (strong, nonatomic) IBOutlet UIView  *mxkContentView;
@property (strong, nonatomic) IBOutlet UILabel *mxkLabel;

/**
 The following constraints are defined between the label and the content view (no relative to margin)
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkLabelLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkLabelTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkLabelTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkLabelBottomConstraint;

@end
