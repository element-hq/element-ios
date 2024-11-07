/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

#import "MXKRecentTableViewCell.h"

/**
 `MXKInterleavedRecentTableViewCell` instances display a room in the context of the recents list.
 */
@interface MXKInterleavedRecentTableViewCell : MXKRecentTableViewCell

@property (weak, nonatomic) IBOutlet UIView* userFlag;

@end
