/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomIncomingBubbleTableViewCell.h"

#import "MXKRoomBubbleCellData.h"

#import "NSBundle+MatrixKit.h"

@implementation MXKRoomIncomingBubbleTableViewCell

- (void)finalizeInit
{
    [super finalizeInit];
    self.readReceiptsAlignment = ReadReceiptAlignmentRight;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.typingBadge.image = [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_keyboard"];
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];
    
    if (bubbleData)
    {
        // Handle here typing badge (if any)
        if (self.typingBadge)
        {
            if (bubbleData.isTyping)
            {
                self.typingBadge.hidden = NO;
                [self.typingBadge.superview bringSubviewToFront:self.typingBadge];
            }
            else
            {
                self.typingBadge.hidden = YES;
            }
        }
    }
}

- (void)didEndDisplay
{
    [super didEndDisplay];
    self.readReceiptsAlignment = ReadReceiptAlignmentRight;
}

@end
