/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewCell.h"

/**
 'MXKTableViewCellWithLabelAndSwitch' inherits 'MXKTableViewCell' class.
 It constains a 'UILabel' and a 'UISwitch' vertically centered.
 */
@interface MXKTableViewCellWithLabelAndSwitch : MXKTableViewCell

@property (strong, nonatomic) IBOutlet UILabel *mxkLabel;
@property (strong, nonatomic) IBOutlet UISwitch *mxkSwitch;

/**
 Leading/Trailing constraints define here spacing to nearest neighbor (no relative to margin)
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkLabelLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkSwitchLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkSwitchTrailingConstraint;

@end
