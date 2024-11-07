/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

/**
 `RoomOutgoingAttachmentBubbleCell` displays outgoing attachment bubbles.
 */
@interface RoomOutgoingAttachmentBubbleCell : MXKRoomOutgoingAttachmentBubbleCell

/**
 Render specifically outgoing attachment.

 There is no multi-inheritance here and some Vector RoomOutgoingAttachmentBubbleCell* classes
 do not inherit from this class but from MXKRoomOutgoingAttachmentBubbleCell directly.
 So, they have to call this method in their `render` method implementation.

 @param cellData the data object to render.
 @param bubbleCell the RoomOutgoingAttachmentBubbleCell cell to render to.
 */
+ (void)render:(MXKCellData *)cellData inBubbleCell:(MXKRoomOutgoingAttachmentBubbleCell*)bubbleCell;

@end
