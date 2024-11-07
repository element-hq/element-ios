/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomOutgoingBubbleTableViewCell.h"

/**
 `MXKRoomIOSBubbleTableViewCell` instances mimic bubbles in the stock iOS messages application.
 It is dedicated to outgoing messages.
 It subclasses `MXKRoomOutgoingBubbleTableViewCell` to take benefit of the available mechanic.
 */
@interface MXKRoomIOSOutgoingBubbleTableViewCell : MXKRoomOutgoingBubbleTableViewCell

/**
 The green bubble displayed in background.
 */
@property (weak, nonatomic) IBOutlet UIImageView *bubbleImageView;

/**
 The width constraint on this backgroung green bubble.
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bubbleImageViewWidthConstraint;

@end
