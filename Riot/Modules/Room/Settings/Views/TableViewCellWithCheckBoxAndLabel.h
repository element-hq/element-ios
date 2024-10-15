/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

@interface TableViewCellWithCheckBoxAndLabel : MXKTableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *checkBox;
@property (strong, nonatomic) IBOutlet UILabel *label;

@property (nonatomic, getter=isEnabled) BOOL enabled;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *checkBoxLeadingConstraint;

@end
