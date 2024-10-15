/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewCell.h"

/**
 'MXKTableViewCellWithButtons' inherits 'MXKTableViewCell' class.
 It displays several buttons with the system style in a UITableViewCell. All buttons have the same width and they are horizontally aligned.
 They are vertically centered.
 */
@interface MXKTableViewCellWithButtons : MXKTableViewCell

/**
 The number of buttons
 */
@property (nonatomic) NSUInteger mxkButtonNumber;

/**
 The current array of buttons
 */
@property (nonatomic) NSArray *mxkButtons;

@end