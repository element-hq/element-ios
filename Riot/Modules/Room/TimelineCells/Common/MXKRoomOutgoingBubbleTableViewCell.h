/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomBubbleTableViewCell.h"

/**
 `MXKRoomOutgoingBubbleTableViewCell` inherits from 'MXKRoomBubbleTableViewCell' class in order to handle specific
 options related to outgoing messages (like unsent labels, upload progress in case of attachment).
 
 In order to optimize bubbles rendering, we advise to define a .xib for each layout.
 */
@interface MXKRoomOutgoingBubbleTableViewCell : MXKRoomBubbleTableViewCell

@end
