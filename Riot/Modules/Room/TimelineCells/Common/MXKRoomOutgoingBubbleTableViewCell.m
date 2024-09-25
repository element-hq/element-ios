/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomOutgoingBubbleTableViewCell.h"

#import "MXEvent+MatrixKit.h"

#import "NSBundle+Matrixkit.h"

#import "MXKRoomBubbleCellData.h"

#import "MXKSwiftHeader.h"

@implementation MXKRoomOutgoingBubbleTableViewCell

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];
    
    if (bubbleData)
    {
        // Add unsent label for failed components (except if the app customizes it) 
        if (self.bubbleInfoContainer && (bubbleData.useCustomUnsentButton == NO))
        {
            for (MXKRoomBubbleComponent *component in bubbleData.bubbleComponents)
            {
                if (component.event.sentState == MXEventSentStateFailed)
                {
                    UIButton *unsentButton = [[UIButton alloc] initWithFrame:CGRectMake(0, component.position.y, 58 , 20)];
                    
                    [unsentButton setTitle:[VectorL10n unsent] forState:UIControlStateNormal];
                    [unsentButton setTitle:[VectorL10n unsent] forState:UIControlStateSelected];
                    [unsentButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
                    [unsentButton setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
                    
                    unsentButton.backgroundColor = [UIColor whiteColor];
                    unsentButton.titleLabel.font =  [UIFont systemFontOfSize:14];
                    
                    [unsentButton addTarget:self action:@selector(onResendToggle:) forControlEvents:UIControlEventTouchUpInside];
                    
                    [self.bubbleInfoContainer addSubview:unsentButton];
                    self.bubbleInfoContainer.hidden = NO;
                    self.bubbleInfoContainer.userInteractionEnabled = YES;
                    
                    // ensure that bubbleInfoContainer is at front to catch the tap event
                    [self.bubbleInfoContainer.superview bringSubviewToFront:self.bubbleInfoContainer];
                }
            }
        }
    }
}

- (void)didEndDisplay
{
    [super didEndDisplay];
    
    self.bubbleInfoContainer.userInteractionEnabled = NO;
}

#pragma mark - User actions

- (IBAction)onResendToggle:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]] && self.delegate)
    {
        MXEvent *selectedEvent = nil;
        
        NSArray *bubbleComponents = bubbleData.bubbleComponents;
        
        if (bubbleComponents.count == 1)
        {
            MXKRoomBubbleComponent *component = [bubbleComponents firstObject];
            selectedEvent = component.event;
        }
        else if (bubbleComponents.count)
        {
            // Here the selected view is a textView (attachment has no more than one component)
            
            // Look for the selected component
            UIButton *unsentButton = (UIButton *)sender;
            for (MXKRoomBubbleComponent *component in bubbleComponents)
            {
                // Ignore components without display.
                if (!component.attributedTextMessage)
                {
                    continue;
                }
                
                if (unsentButton.frame.origin.y == component.position.y)
                {
                    selectedEvent = component.event;
                    break;
                }
            }
        }
        
        if (selectedEvent)
        {
            [self.delegate cell:self didRecognizeAction:kMXKRoomBubbleCellUnsentButtonPressed userInfo:@{kMXKRoomBubbleCellEventKey:selectedEvent}];
        }
    }
}

@end
