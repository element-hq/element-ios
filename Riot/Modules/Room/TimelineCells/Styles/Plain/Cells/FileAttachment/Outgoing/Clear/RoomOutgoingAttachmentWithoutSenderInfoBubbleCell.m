/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"
#import "RoomBubbleCellData.h"
#import "MXKRoomBubbleTableViewCell+Riot.h"

@implementation RoomOutgoingAttachmentWithoutSenderInfoBubbleCell

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];

    [RoomOutgoingAttachmentBubbleCell render:cellData inBubbleCell:self];
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
