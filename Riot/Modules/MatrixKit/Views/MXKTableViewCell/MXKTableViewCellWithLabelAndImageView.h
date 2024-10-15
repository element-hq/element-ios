/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewCell.h"

/**
 'MXKTableViewCellWithLabelAndImageView' inherits 'MXKTableViewCell' class.
 It constains a 'UILabel' and a 'UIImageView' vertically centered.
 */
@interface MXKTableViewCellWithLabelAndImageView : MXKTableViewCell

@property (strong, nonatomic) IBOutlet UILabel *mxkLabel;
@property (strong, nonatomic) IBOutlet UIImageView *mxkImageView;

/**
 Leading/Trailing constraints define here spacing to nearest neighbor (no relative to margin)
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkLabelLeadingConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkImageViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkImageViewTrailingConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkImageViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkImageViewHeightConstraint;

/**
 The image view display box type ('MXKTableViewCellDisplayBoxTypeDefault' by default)
 */
@property (nonatomic) MXKTableViewCellDisplayBoxType mxkImageViewDisplayBoxType;

@end
