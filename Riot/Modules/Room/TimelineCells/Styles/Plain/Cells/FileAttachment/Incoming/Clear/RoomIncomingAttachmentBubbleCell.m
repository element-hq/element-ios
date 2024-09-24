/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

#import "RoomIncomingAttachmentBubbleCell.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"
#import "MXKRoomBubbleTableViewCell+Riot.h"

@implementation RoomIncomingAttachmentBubbleCell

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    [self updateUserNameColor];
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];
 
    [self updateUserNameColor];
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
