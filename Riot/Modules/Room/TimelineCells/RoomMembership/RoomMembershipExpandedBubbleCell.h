/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomMembershipBubbleCell.h"

/**
 Action identifier used when the user tapped on the "collapse" button.
 */
extern NSString *const kRoomMembershipExpandedBubbleCellTapOnCollapseButton;

/**
 `RoomMembershipExpandedBubbleCell` displays the first membership event of series
 that can be collapsable.
 */
@interface RoomMembershipExpandedBubbleCell : RoomMembershipBubbleCell

@property (weak, nonatomic) IBOutlet UIButton *collapseButton;
@property (weak, nonatomic) IBOutlet UIView *separatorView;

@end
