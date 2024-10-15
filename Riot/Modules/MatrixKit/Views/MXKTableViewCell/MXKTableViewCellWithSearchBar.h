/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewCell.h"

/**
 'MXKTableViewCellWithSearchBar' inherits 'MXKTableViewCell' class.
 It constains a 'UISearchBar' vertically centered.
 */
@interface MXKTableViewCellWithSearchBar : MXKTableViewCell

@property (strong, nonatomic) IBOutlet UISearchBar *mxkSearchBar;

/**
 Leading/Trailing constraints define here spacing to nearest neighbor (no relative to margin)
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkSearchBarLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkSearchBarTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkSearchBarBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkSearchBarTrailingConstraint;

@end