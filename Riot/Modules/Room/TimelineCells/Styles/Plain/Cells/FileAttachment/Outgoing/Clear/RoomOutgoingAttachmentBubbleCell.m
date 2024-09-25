/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomOutgoingAttachmentBubbleCell.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"
#import "MXKRoomBubbleTableViewCell+Riot.h"

@implementation RoomOutgoingAttachmentBubbleCell

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    [self updateUserNameColor];
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];

    [self updateUserNameColor];
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
            bubbleCell.attachmentView.layer.borderColor = ThemeService.shared.theme.warningColor.CGColor;
            bubbleCell.attachmentView.layer.borderWidth = 1;
        }
        else
        {
            bubbleCell.attachmentView.layer.borderWidth = 0;
        }
    }
}

+ (CGFloat)heightForCellData:(MXKCellData*)cellData withMaximumWidth:(CGFloat)maxWidth
{
    CGFloat rowHeight = [self attachmentBubbleCellHeightForCellData:cellData withMaximumWidth:maxWidth];
    
    if (rowHeight <= 0)
    {
        rowHeight = [super heightForCellData:cellData withMaximumWidth:maxWidth];
    }
    
    return rowHeight;
}

@end
