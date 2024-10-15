/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomIOSBubbleTableViewCell.h"

#import "MXKRoomBubbleCellDataStoring.h"

@implementation MXKRoomIOSBubbleTableViewCell

- (void)render:(MXKCellData *)cellData
{
    id<MXKRoomBubbleCellDataStoring> bubbleData = (id<MXKRoomBubbleCellDataStoring>)cellData;
    if (bubbleData)
    {
        self.textLabel.attributedText = bubbleData.attributedTextMessage;
    }
    else
    {
        self.textLabel.text = @"";
    }
    
    // Light custo for now... @TODO
    self.layer.cornerRadius = 20;
    self.backgroundColor = [UIColor blueColor];
}

+ (CGFloat)heightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    return 44;
}

@end
