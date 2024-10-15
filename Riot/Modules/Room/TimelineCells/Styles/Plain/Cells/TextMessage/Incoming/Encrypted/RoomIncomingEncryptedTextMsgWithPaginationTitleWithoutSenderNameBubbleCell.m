/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomIncomingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.h"

#import "RoomEncryptedDataBubbleCell.h"

#import "RoomBubbleCellData.h"

@implementation RoomIncomingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell

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
