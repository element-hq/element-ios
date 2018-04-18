/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
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

#import "RoomOutgoingAttachmentBubbleCell.h"

#import "RiotDesignValues.h"

@implementation RoomOutgoingAttachmentBubbleCell

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.userNameLabel.textColor = kRiotPrimaryTextColor;
    self.messageTextView.tintColor = kRiotColorGreen;
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];

    [RoomOutgoingAttachmentBubbleCell render:cellData inBubbleCell:self];
}

- (void)didEndDisplay
{
    [super didEndDisplay];
}

+ (void)render:(MXKCellData *)cellData inBubbleCell:(MXKRoomOutgoingAttachmentBubbleCell *)bubbleCell
{
    if (bubbleCell.attachmentView && bubbleCell->bubbleData.isAttachmentWithThumbnail)
    {
        // Show a red border when the attachment sending failed
        if (bubbleCell->bubbleData.attachment.eventSentState == MXEventSentStateFailed)
        {
            bubbleCell.attachmentView.layer.borderColor = kRiotColorPinkRed.CGColor;
            bubbleCell.attachmentView.layer.borderWidth = 1;
        }
        else
        {
            bubbleCell.attachmentView.layer.borderWidth = 0;
        }
    }
}

@end
