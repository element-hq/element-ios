/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewCell.h"

/**
 'MXKTableViewCellWithButton' inherits 'MXKTableViewCell' class.
 It constains a 'UIButton' centered in cell content view.
 */
@interface MXKTableViewCellWithButton : MXKTableViewCell

@property (strong, nonatomic) IBOutlet UIButton *mxkButton;

@end