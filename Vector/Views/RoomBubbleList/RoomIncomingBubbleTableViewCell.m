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

#import "NSBundle+MatrixKit.h"

#pragma mark - UI Constant definitions
#define MXKROOMBUBBLETABLEVIEWCELL_INCOMING_HEIGHT_REDUCTION_WHEN_SENDER_INFO_IS_HIDDEN -10

@implementation RoomIncomingBubbleTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.typingBadge.image = [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_keyboard"];
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];
    
    if (self.bubbleData)
    {
        // Check whether the previous message has been sent by the same user.
        // The user's picture and name are displayed only for the first message.
        // Handle sender's picture and adjust view's constraints
        if (self.bubbleData.isSameSenderAsPreviousBubble)
        {
            self.pictureView.hidden = YES;
            self.msgTextViewTopConstraint.constant = self.class.cellWithOriginalXib.msgTextViewTopConstraint.constant + MXKROOMBUBBLETABLEVIEWCELL_INCOMING_HEIGHT_REDUCTION_WHEN_SENDER_INFO_IS_HIDDEN;
            self.attachViewTopConstraint.constant = self.class.cellWithOriginalXib.attachViewTopConstraint.constant + MXKROOMBUBBLETABLEVIEWCELL_INCOMING_HEIGHT_REDUCTION_WHEN_SENDER_INFO_IS_HIDDEN;
            
            if (!self.dateTimeLabelContainer.hidden)
            {
                self.dateTimeLabelContainerTopConstraint.constant += MXKROOMBUBBLETABLEVIEWCELL_INCOMING_HEIGHT_REDUCTION_WHEN_SENDER_INFO_IS_HIDDEN;
            }
        }
        
        // Display user's display name except if the name appears in the displayed text (see emote and membership event)
        self.userNameLabel.hidden = (self.bubbleData.isSameSenderAsPreviousBubble || self.bubbleData.startsWithSenderName);
        self.userNameLabel.text = self.bubbleData.senderDisplayName;
        // Set typing badge visibility
        self.typingBadge.hidden = (self.pictureView.hidden || !self.bubbleData.isTyping);
        if (!self.typingBadge.hidden)
        {
            [self.typingBadge.superview bringSubviewToFront:self.typingBadge];
        }
    }
}

+ (CGFloat)heightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    CGFloat rowHeight = [super heightForCellData:cellData withMaximumWidth:maxWidth];
    
    MXKRoomBubbleCellData *bubbleData = (MXKRoomBubbleCellData*)cellData;
    
    // Check whether the previous message has been sent by the same user.
    // The user's picture and name are displayed only for the first message.
    if (bubbleData.isSameSenderAsPreviousBubble)
    {
        // Reduce top margin -> row height reduction
        rowHeight += MXKROOMBUBBLETABLEVIEWCELL_INCOMING_HEIGHT_REDUCTION_WHEN_SENDER_INFO_IS_HIDDEN;
    }
    else
    {
        // We consider a minimun cell height in order to display correctly user's picture
        if (rowHeight < self.cellWithOriginalXib.frame.size.height)
        {
            rowHeight = self.cellWithOriginalXib.frame.size.height;
        }
    }
    
    return rowHeight;
}

@end
