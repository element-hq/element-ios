/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomIncomingTextMsgBubbleCell.h"

/**
 `RoomMembershipBubbleCell` displays a membership event.
 */
@interface RoomMembershipBubbleCell : RoomIncomingTextMsgBubbleCell

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pictureViewTopConstraint;

@end
