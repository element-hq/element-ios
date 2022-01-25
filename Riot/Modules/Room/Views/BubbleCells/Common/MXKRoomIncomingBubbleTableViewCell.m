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
