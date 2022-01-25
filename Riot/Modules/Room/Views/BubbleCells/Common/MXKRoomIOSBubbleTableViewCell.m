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
