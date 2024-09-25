/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewCell.h"

/**
 'MXKTableViewCellWithLabelAndSlider' inherits 'MXKTableViewCell' class.
 It constains a 'UILabel' and a 'UISlider'.
 */
@interface MXKTableViewCellWithLabelAndSlider : MXKTableViewCell

@property (nonatomic) IBOutlet UILabel *mxkLabel;
@property (nonatomic) IBOutlet UISlider *mxkSlider;

/**
 Leading/Trailing constraints define here spacing to nearest neighbor (no relative to margin)
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkLabelTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkLabelLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkLabelTrailingConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkSliderTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkSliderLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkSliderTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkSliderBottomConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkSliderHeightConstraint;

@end
