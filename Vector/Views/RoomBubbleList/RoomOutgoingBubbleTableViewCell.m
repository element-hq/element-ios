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

#import "RoomOutgoingBubbleTableViewCell.h"

#pragma mark - UI Constant definitions
#define MXKROOMBUBBLETABLEVIEWCELL_OUTGOING_HEIGHT_REDUCTION_WHEN_SENDER_INFO_IS_HIDDEN -10

@interface RoomOutgoingBubbleTableViewCell ()
{
    BOOL showBubbleDateTimeFlag;
}

@end

@implementation RoomOutgoingBubbleTableViewCell

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
        
        // Check whether a new pagination start at this bubble
        if (self.bubbleData.isPaginationFirstBubble)
        {
            self.paginationTitleViewHeightConstraint.constant = 20;
            self.paginationLabel.text = [self.bubbleData.eventFormatter dateStringFromDate:self.bubbleData.date withTime:NO];
        }
        else
        {
            self.paginationTitleViewHeightConstraint.constant = 0;
        }
        
        // TODO handle here unsent
        
        // Add unsent label for failed components
//        for (MXKRoomBubbleComponent *component in self.bubbleData.bubbleComponents)
//        {
//            if (component.event.mxkState == MXKEventStateSendingFailed)
//            {
//                UIButton *unsentButton = [[UIButton alloc] initWithFrame:CGRectMake(0, component.position.y, 58 , 20)];
//                
//                [unsentButton setTitle:[NSBundle mxk_localizedStringForKey:@"unsent"] forState:UIControlStateNormal];
//                [unsentButton setTitle:[NSBundle mxk_localizedStringForKey:@"unsent"] forState:UIControlStateSelected];
//                [unsentButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
//                [unsentButton setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
//                
//                unsentButton.backgroundColor = [UIColor whiteColor];
//                unsentButton.titleLabel.font =  [UIFont systemFontOfSize:14];
//                
//                [unsentButton addTarget:self action:@selector(onResendToggle:) forControlEvents:UIControlEventTouchUpInside];
//                
//                [self.dateTimeLabelContainer addSubview:unsentButton];
//                self.dateTimeLabelContainer.hidden = NO;
//                self.dateTimeLabelContainer.userInteractionEnabled = YES;
//                
//                // ensure that dateTimeLabelContainer is at front to catch the tap event
//                [self.dateTimeLabelContainer.superview bringSubviewToFront:self.dateTimeLabelContainer];
//            }
//        }
    }
}

+ (CGFloat)heightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    CGFloat rowHeight = [super heightForCellData:cellData withMaximumWidth:maxWidth];
    
    MXKRoomBubbleCellData *bubbleData = (MXKRoomBubbleCellData*)cellData;
    
    // Check whether a new pagination start at this bubble
    // The pagination label is displayed with the first bubble of the pagination
    if (bubbleData.isPaginationFirstBubble)
    {
        rowHeight += 20;
    }
    
    return rowHeight;
}

@end