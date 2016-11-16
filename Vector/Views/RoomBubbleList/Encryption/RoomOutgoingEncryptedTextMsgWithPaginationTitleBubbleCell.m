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

#import "RoomOutgoingEncryptedTextMsgWithPaginationTitleBubbleCell.h"

#import "RoomEncryptedDataBubbleCell.h"

@implementation RoomOutgoingEncryptedTextMsgWithPaginationTitleBubbleCell

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
        
        // Ensure that older subviews are removed
        // They should be (they are removed when the cell is not anymore used).
        // But, it seems that is not always true.
        NSArray* views = [self.encryptionStatusContainerView subviews];
        for(UIView* view in views)
        {
            [view removeFromSuperview];
        }
        
        for (MXKRoomBubbleComponent *component in bubbleData.bubbleComponents)
        {
            UIImage *icon = [RoomEncryptedDataBubbleCell encryptionIconForEvent:component.event andSession:bubbleData.mxSession];
            UIImageView *encryptStatusImageView = [[UIImageView alloc] initWithImage:icon];
            
            CGRect frame = encryptStatusImageView.frame;
            frame.origin.y = component.position.y + 3;
            encryptStatusImageView.frame = frame;
            
            CGPoint center = encryptStatusImageView.center;
            center.x = self.encryptionStatusContainerView.frame.size.width / 2;
            encryptStatusImageView.center = center;
            
            [self.encryptionStatusContainerView addSubview:encryptStatusImageView];
        }
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
        
        // Consider by default the first component
        MXKRoomBubbleComponent *tappedComponent = bubbleComponents.firstObject;
        
        CGPoint tapPoint = [sender locationInView:self.messageTextView];
        
        for (NSInteger index = 1; index < bubbleComponents.count; index++)
        {
            // Here the bubble is composed by multiple text messages
            MXKRoomBubbleComponent *component = bubbleComponents[index];
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