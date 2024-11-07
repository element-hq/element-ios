/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewCell.h"

/**
 'MXKTableViewCellWithLabelAndButton' inherits 'MXKTableViewCell' class.
 It constains a 'UILabel' and a 'UIButton' vertically centered.
 */
@interface MXKTableViewCellWithLabelAndButton : MXKTableViewCell

@property (strong, nonatomic) IBOutlet UILabel *mxkLabel;
@property (strong, nonatomic) IBOutlet UIButton *mxkButton;

/**
 Leading/Trailing constraints define here spacing to nearest neighbor (no relative to margin)
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkLabelLeadingConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkButtonLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkButtonTrailingConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkButtonProportionalWidthToMxkButtonConstraint;

@end
