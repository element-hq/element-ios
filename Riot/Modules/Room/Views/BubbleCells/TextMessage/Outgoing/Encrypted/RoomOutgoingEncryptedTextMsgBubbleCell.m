/*
 Copyright 2016 OpenMarket Ltd
 
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

#import "RoomOutgoingEncryptedTextMsgBubbleCell.h"

#import "RoomEncryptedDataBubbleCell.h"

#import "RoomBubbleCellData.h"

@implementation RoomOutgoingEncryptedTextMsgBubbleCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Listen to encryption icon tap
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onEncryptionIconTap:)];
    [tapGesture setNumberOfTouchesRequired:1];
    [tapGesture setNumberOfTapsRequired:1];
    [tapGesture setDelegate:self];
    [self.encryptionStatusContainerView addGestureRecognizer:tapGesture];
    self.encryptionStatusContainerView.userInteractionEnabled = YES;
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];
    
    if (bubbleData)
    {
        // Set the right device info icon in front of each event
        [RoomEncryptedDataBubbleCell addEncryptionStatusFromBubbleData:bubbleData inContainerView:self.encryptionStatusContainerView];
    }
}

- (void)didEndDisplay
{
    NSArray* subviews = self.encryptionStatusContainerView.subviews;
    for (UIView *view in subviews)
    {
        [view removeFromSuperview];
    }
    
    [super didEndDisplay];
}

#pragma mark - User actions

- (IBAction)onEncryptionIconTap:(UITapGestureRecognizer*)sender
{
    if (self.delegate)
    {
        // Check which bubble component is displayed in front of the tapped line.
        NSArray *bubbleComponents = bubbleData.bubbleComponents;
        
        // Consider by default the first display component
        NSInteger firstComponentIndex = 0;
        if ([bubbleData isKindOfClass:RoomBubbleCellData.class])
        {
            firstComponentIndex = ((RoomBubbleCellData*)bubbleData).oldestComponentIndex;
        }
        MXKRoomBubbleComponent *tappedComponent = bubbleComponents[firstComponentIndex++];
        
        CGPoint tapPoint = [sender locationInView:self.messageTextView];
        
        for (NSInteger index = firstComponentIndex; index < bubbleComponents.count; index++)
        {
            // Here the bubble is composed by multiple text messages
            MXKRoomBubbleComponent *component = bubbleComponents[index];
            
            // Ignore components without display.
            if (!component.attributedTextMessage)
            {
                continue;
            }
            
            if (tapPoint.y < component.position.y)
            {
                break;
            }
            tappedComponent = component;
        }
        
        if (tappedComponent)
        {
            MXEvent *tappedEvent = tappedComponent.event;
            [self.delegate cell:self didRecognizeAction:kRoomEncryptedDataBubbleCellTapOnEncryptionIcon userInfo:(tappedEvent ? @{kMXKRoomBubbleCellEventKey:tappedEvent} : nil)];
        }
    }
}

@end
