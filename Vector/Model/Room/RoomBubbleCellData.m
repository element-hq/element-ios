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

#import "RoomBubbleCellData.h"

#import "EventFormatter.h"

#import "AvatarGenerator.h"

#define VECTOR_ROOM_BUBBLE_CELL_DATA_TEXTVIEW_MARGIN 10

static NSAttributedString *readReceiptVerticalWhitespace = nil;

@implementation RoomBubbleCellData

#pragma mark - Override MXKRoomBubbleCellData

- (instancetype)initWithEvent:(MXEvent *)event andRoomState:(MXRoomState *)roomState andRoomDataSource:(MXKRoomDataSource *)roomDataSource2
{
    self = [super initWithEvent:event andRoomState:roomState andRoomDataSource:roomDataSource2];
    
    if (self)
    {
        // Use the vector style placeholder
        self.senderAvatarPlaceholder = [AvatarGenerator generateRoomMemberAvatar:self.senderId displayName:self.senderDisplayName];
        
        // Check whether some read receipts are linked to this event
        _hasReadReceipts = NO;
        if ([roomDataSource.room getEventReceipts:event.eventId sorted:NO])
        {
            _hasReadReceipts = YES;
            
            // Update attributed string by inserting vertical whitespace at the end to display read receipts
            NSMutableAttributedString *updatedAttributedTextMsg = [[NSMutableAttributedString alloc] initWithAttributedString:attributedTextMessage];
            [updatedAttributedTextMsg appendAttributedString:[RoomBubbleCellData readReceiptVerticalWhitespace]];
            
            // Update the current text message by reseting content size
            self.attributedTextMessage = updatedAttributedTextMsg;
        }
    }
    
    return self;
}

- (NSAttributedString*)attributedTextMessageWithHighlightedEvent:(NSString*)eventId tintColor:(UIColor*)tintColor
{
    // Use this method to highlight a component in text message:
    // The selected component is unchanged, while an alpha is applied on other components.
    NSMutableAttributedString *customAttributedTextMsg;
    NSAttributedString *componentString;
    
    @synchronized(bubbleComponents)
    {
        for (MXKRoomBubbleComponent* component in bubbleComponents)
        {
            componentString = component.attributedTextMessage;
            
            if ([component.event.eventId isEqualToString:eventId] == NO)
            {
                // Apply alpha to blur this component
                NSMutableAttributedString *customComponentString = [[NSMutableAttributedString alloc] initWithAttributedString:componentString];
                UIColor *color = [componentString attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:nil];
                color = [color colorWithAlphaComponent:0.2];
                                
                [customComponentString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, customComponentString.length)];
                componentString = customComponentString;
            }
            
            if (!customAttributedTextMsg)
            {
                customAttributedTextMsg = [[NSMutableAttributedString alloc] initWithAttributedString:componentString];
            }
            else
            {
                // Append attributed text
                [customAttributedTextMsg appendAttributedString:[MXKRoomBubbleCellDataWithAppendingMode messageSeparator]];
                [customAttributedTextMsg appendAttributedString:componentString];
            }
            
            // Add vertical whitespace in case of read receipts
            if ([roomDataSource.room getEventReceipts:component.event.eventId sorted:NO])
            {
                _hasReadReceipts = YES;
                [customAttributedTextMsg appendAttributedString:[RoomBubbleCellData readReceiptVerticalWhitespace]];
            }
        }
    }
    
    return customAttributedTextMsg;
}

- (void)prepareBubbleComponentsPosition
{
    if (shouldUpdateComponentsPosition)
    {
        _hasReadReceipts = NO;
        
        @synchronized(bubbleComponents)
        {
            // Check whether there is at least one component.
            if (bubbleComponents.count)
            {
                // Set position of the first component
                MXKRoomBubbleComponent *firstComponent = [bubbleComponents firstObject];
                
                CGFloat positionY = (self.attachment == nil || self.attachment.type == MXKAttachmentTypeFile) ? VECTOR_ROOM_BUBBLE_CELL_DATA_TEXTVIEW_MARGIN : 0;
                firstComponent.position = CGPointMake(0, positionY);
                
                _hasReadReceipts = ([roomDataSource.room getEventReceipts:firstComponent.event.eventId sorted:NO] != nil);
                
                // Check whether the position of other components need to be refreshed
                if (!self.attachment && bubbleComponents.count > 1)
                {
                    // Compute height of the first text component
                    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:firstComponent.attributedTextMessage];
                    
                    // Vertical whitescape is added in case of read receipts
                    if (_hasReadReceipts)
                    {
                        [attributedString appendAttributedString:[RoomBubbleCellData readReceiptVerticalWhitespace]];
                    }
                    
                    
                    CGFloat componentHeight = [self rawTextHeight:attributedString];
                    
                    // Set position for each other component
                    CGFloat positionY = firstComponent.position.y;
                    CGFloat cumulatedHeight = 0;
                    
                    for (NSUInteger index = 1; index < bubbleComponents.count; index++)
                    {
                        cumulatedHeight += componentHeight;
                        positionY += componentHeight;
                        
                        MXKRoomBubbleComponent *component = [bubbleComponents objectAtIndex:index];
                        component.position = CGPointMake(0, positionY);
                        
                        // Compute height of the current component
                        [attributedString appendAttributedString:[MXKRoomBubbleCellDataWithAppendingMode messageSeparator]];
                        [attributedString appendAttributedString:component.attributedTextMessage];
                        
                        // Add vertical whitespace in case of read receipts
                        if ([roomDataSource.room getEventReceipts:component.event.eventId sorted:NO])
                        {
                            _hasReadReceipts = YES;
                            [attributedString appendAttributedString:[RoomBubbleCellData readReceiptVerticalWhitespace]];
                        }
                        
                        componentHeight = [self rawTextHeight:attributedString] - cumulatedHeight;
                    }
                }
            }
        }
        
        shouldUpdateComponentsPosition = NO;
    }
}

- (NSAttributedString*)attributedTextMessage
{
    @synchronized(bubbleComponents)
    {
        if (!attributedTextMessage.length && bubbleComponents.count)
        {
            _hasReadReceipts = NO;
            
            // Create attributed string
            NSMutableAttributedString *currentAttributedTextMsg;
            
            for (MXKRoomBubbleComponent* component in bubbleComponents)
            {
                if (!currentAttributedTextMsg)
                {
                    currentAttributedTextMsg = [[NSMutableAttributedString alloc] initWithAttributedString:component.attributedTextMessage];
                }
                else
                {
                    // Append attributed text
                    [currentAttributedTextMsg appendAttributedString:[MXKRoomBubbleCellDataWithAppendingMode messageSeparator]];
                    [currentAttributedTextMsg appendAttributedString:component.attributedTextMessage];
                }
                
                // Add vertical whitespace in case of read receipts
                if ([roomDataSource.room getEventReceipts:component.event.eventId sorted:NO])
                {
                    _hasReadReceipts = YES;
                    [currentAttributedTextMsg appendAttributedString:[RoomBubbleCellData readReceiptVerticalWhitespace]];
                }
            }
            attributedTextMessage = currentAttributedTextMsg;
        }
    }
    
    return attributedTextMessage;
}

#pragma mark -

+ (NSAttributedString *)readReceiptVerticalWhitespace
{
    @synchronized(self)
    {
        if (readReceiptVerticalWhitespace == nil)
        {
            readReceiptVerticalWhitespace = [[NSAttributedString alloc] initWithString:@"\n\n" attributes:@{NSForegroundColorAttributeName : [UIColor blackColor],
                                                                                               NSFontAttributeName: [UIFont systemFontOfSize:4]}];
        }
    }
    return readReceiptVerticalWhitespace;
}

@end
