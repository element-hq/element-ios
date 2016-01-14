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

#import "RoomIncomingTextMsgWithPaginationTitleBubbleCell.h"

#import "VectorDesignValues.h"

@implementation RoomIncomingTextMsgWithPaginationTitleBubbleCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.userNameLabel.textColor = VECTOR_TEXT_BLACK_COLOR;
    
    self.paginationLabel.textColor = VECTOR_GREEN_COLOR;
    self.paginationSeparatorView.backgroundColor = VECTOR_GREEN_COLOR;
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];
    
    if (self.userNameLabel.isHidden)
    {
        // Adjust the top constraint of the message text view (This constraint is restored at the end of cell use see [didEndDisplay]).
        self.msgTextViewTopConstraint.constant -= self.userNameLabel.frame.size.height;
    }
    
    if (self.bubbleData)
    {
        self.paginationLabel.text = [[self.bubbleData.eventFormatter dateStringFromDate:self.bubbleData.date withTime:NO] uppercaseString];
    }
}

- (void)didEndDisplay
{
    // Restore the top constraint of the message text view if it has been modified during rendering
    if (self.userNameLabel.isHidden)
    {
        self.msgTextViewTopConstraint.constant += self.userNameLabel.frame.size.height;
    }
    
    [super didEndDisplay];
}

@end
