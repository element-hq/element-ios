/*
 Copyright 2015 OpenMarket Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
