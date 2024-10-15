/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewCell.h"

/**
 'MXKTableViewCellWithPicker' inherits 'MXKTableViewCell' class.
 It constains a 'UIPickerView' vertically centered.
 */
@interface MXKTableViewCellWithPicker : MXKTableViewCell

@property (strong, nonatomic) IBOutlet UIPickerView* mxkPickerView;

/**
 Leading/Trailing constraints define here spacing to nearest neighbor (no relative to margin)
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkPickerViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkPickerViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkPickerViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkPickerViewTrailingConstraint;

@end
