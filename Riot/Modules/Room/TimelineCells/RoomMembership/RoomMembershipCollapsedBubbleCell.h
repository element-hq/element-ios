/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomIncomingTextMsgBubbleCell.h"

/**
 `RoomMembershipCollapsedBubbleCell` displays a sum-up of collapsed membership cells.
 */
@interface RoomMembershipCollapsedBubbleCell : RoomIncomingTextMsgBubbleCell

@property (weak, nonatomic) IBOutlet UIView *avatarsView;

@end
