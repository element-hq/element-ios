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

#import "RoomIncomingBubbleTableViewCell.h"

@interface RoomIncomingBubbleTableViewCell ()
{
    BOOL showBubbleDateTimeFlag;
}

@end

@implementation RoomIncomingBubbleTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)dealloc
{
//    [self stopTypingIndicatorAnimating];
}

- (void)setAllTextHighlighted:(BOOL)allTextHighlighted
{
    if (allTextHighlighted)
    {
        // Hide timestamp during selection
        self.bubbleData.showBubbleDateTime = NO;
    }
    else
    {
        // Restore the actual value of the showBubbleDateTime flag
        self.bubbleData.showBubbleDateTime = showBubbleDateTimeFlag;
    }
    
    super.allTextHighlighted = allTextHighlighted;
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];
    
    if (!self.pictureView.isHidden)
    {
        [self.pictureView.layer setCornerRadius:5];
    }
    
    if (self.bubbleData)
    {
        showBubbleDateTimeFlag = self.bubbleData.showBubbleDateTime;
        
        // TODO handle here pagination display per day
        
        // TODO handle here timestamp display
        
        // TODO handle here typing indicator
    }
}

- (void)didEndDisplay
{
    [super didEndDisplay];
    
    // Stop potential typing indicator
//    [self stopTypingIndicatorAnimating];
}

@end
