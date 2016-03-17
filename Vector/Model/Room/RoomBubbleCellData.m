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

static NSAttributedString *timestampVerticalWhitespace = nil;
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
        
        // Increase maximum number of components
        self.maxComponentCount = 20;
        
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

- (void)prepareBubbleComponentsPosition
{
    if (shouldUpdateComponentsPosition)
    {
        // Refresh the receipt flag during this process.
        _hasReadReceipts = NO;
        
        @synchronized(bubbleComponents)
        {
            // Check whether there is at least one component.
            if (bubbleComponents.count)
            {
                // Set position of the first component
                MXKRoomBubbleComponent *component = [bubbleComponents firstObject];
                
                CGFloat positionY = (self.attachment == nil || self.attachment.type == MXKAttachmentTypeFile) ? MXKROOMBUBBLECELLDATA_TEXTVIEW_DEFAULT_VERTICAL_INSET : 0;
                component.position = CGPointMake(0, positionY);
                
                _hasReadReceipts = ([roomDataSource.room getEventReceipts:component.event.eventId sorted:NO] != nil);
                
                // Check whether the position of other components need to be refreshed
                if (!self.attachment && bubbleComponents.count > 1)
                {
                    NSMutableAttributedString *attributedString;
                    NSInteger selectedComponentIndex = self.selectedComponentIndex;
                    NSInteger lastMessageIndex = self.containsLastMessage ? self.mostRecentComponentIndex : NSNotFound;
                    
                    // Check whether the timestamp is displayed for this first component, and check whether a vertical whitespace is required
                    if ((selectedComponentIndex == 0 || lastMessageIndex == 0) && (self.shouldHideSenderInformation || self.shouldHideSenderName))
                    {
                        attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[RoomBubbleCellData timestampVerticalWhitespace]];
                        [attributedString appendAttributedString:component.attributedTextMessage];
                    }
                    else
                    {
                        // Init attributed string with the first text component
                        attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:component.attributedTextMessage];
                    }
                    
                    // Vertical whitespace is added in case of read receipts
                    if (_hasReadReceipts)
                    {
                        [attributedString appendAttributedString:[RoomBubbleCellData readReceiptVerticalWhitespace]];
                    }
                    
                    [attributedString appendAttributedString:[MXKRoomBubbleCellDataWithAppendingMode messageSeparator]];
                    
                    for (NSUInteger index = 1; index < bubbleComponents.count; index++)
                    {
                        // Compute the vertical position for next component
                        component = [bubbleComponents objectAtIndex:index];
                        
                        // Prepare its attributed string by considering potential vertical margin required to display timestamp.
                        NSAttributedString *componentString;
                        if (selectedComponentIndex == index || lastMessageIndex == index)
                        {
                            NSMutableAttributedString *componentAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[RoomBubbleCellData timestampVerticalWhitespace]];
                            [componentAttributedString appendAttributedString:component.attributedTextMessage];
                            
                            componentString = componentAttributedString;
                        }
                        else
                        {
                            componentString = component.attributedTextMessage;
                        }
                        
                        // Append this attributed string.
                        [attributedString appendAttributedString:componentString];
                        
                        // Compute the height of the resulting string.
                        CGFloat cumulatedHeight = [self rawTextHeight:attributedString];
                        
                        // Deduce the position of the beginning of this component.
                        CGFloat positionY = MXKROOMBUBBLECELLDATA_TEXTVIEW_DEFAULT_VERTICAL_INSET + (cumulatedHeight - [self rawTextHeight:componentString]);
                        
                        component.position = CGPointMake(0, positionY);
                        
                        // Add vertical whitespace in case of read receipts.
                        if ([roomDataSource.room getEventReceipts:component.event.eventId sorted:NO])
                        {
                            _hasReadReceipts = YES;
                            [attributedString appendAttributedString:[RoomBubbleCellData readReceiptVerticalWhitespace]];
                        }
                        
                        [attributedString appendAttributedString:[MXKRoomBubbleCellDataWithAppendingMode messageSeparator]];
                    }
                }
            }
        }
        
        shouldUpdateComponentsPosition = NO;
    }
}

- (NSAttributedString*)attributedTextMessage
{
    // Note: When a component is selected, it is highlighted by applying an alpha on other components.
    
    @synchronized(bubbleComponents)
    {
        if (!attributedTextMessage.length && bubbleComponents.count)
        {
            // Refresh the receipt flag during this process
            _hasReadReceipts = NO;
            
            // Create attributed string
            NSMutableAttributedString *currentAttributedTextMsg;
            
            MXKRoomBubbleComponent *component = [bubbleComponents firstObject];
            NSAttributedString *componentString = component.attributedTextMessage;
            
            NSInteger selectedComponentIndex = self.selectedComponentIndex;
            NSInteger lastMessageIndex = self.containsLastMessage ? self.mostRecentComponentIndex : NSNotFound;
            
            // Check whether another component than the first one is selected
            if (selectedComponentIndex != NSNotFound && selectedComponentIndex != 0)
            {
                // Apply alpha to blur this component
                NSMutableAttributedString *customComponentString = [[NSMutableAttributedString alloc] initWithAttributedString:componentString];
                UIColor *color = [componentString attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:nil];
                color = [color colorWithAlphaComponent:0.2];
                
                [customComponentString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, customComponentString.length)];
                componentString = customComponentString;
            }
            
            // Check whether the timestamp is displayed for this first component, and check whether a vertical whitespace is required
            if ((selectedComponentIndex == 0 || lastMessageIndex == 0) && (self.shouldHideSenderInformation || self.shouldHideSenderName))
            {
                currentAttributedTextMsg = [[NSMutableAttributedString alloc] initWithAttributedString:[RoomBubbleCellData timestampVerticalWhitespace]];
                [currentAttributedTextMsg appendAttributedString:componentString];
            }
            else
            {
                // Init attributed string with the first text component
                currentAttributedTextMsg = [[NSMutableAttributedString alloc] initWithAttributedString:componentString];
            }
            
            // Vertical whitespace is added in case of read receipts
            if ([roomDataSource.room getEventReceipts:component.event.eventId sorted:NO])
            {
                [currentAttributedTextMsg appendAttributedString:[RoomBubbleCellData readReceiptVerticalWhitespace]];
            }
            
            for (NSInteger index = 1; index < bubbleComponents.count; index++)
            {
                [currentAttributedTextMsg appendAttributedString:[MXKRoomBubbleCellDataWithAppendingMode messageSeparator]];
                
                component = bubbleComponents[index];
                componentString = component.attributedTextMessage;
                
                // Check whether another component than this one is selected
                if (selectedComponentIndex != NSNotFound && selectedComponentIndex != index)
                {
                    // Apply alpha to blur this component
                    NSMutableAttributedString *customComponentString = [[NSMutableAttributedString alloc] initWithAttributedString:componentString];
                    UIColor *color = [componentString attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:nil];
                    color = [color colorWithAlphaComponent:0.2];
                    
                    [customComponentString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, customComponentString.length)];
                    componentString = customComponentString;
                }
                
                // Check whether the timestamp is displayed
                if (selectedComponentIndex == index || lastMessageIndex == index)
                {
                    [currentAttributedTextMsg appendAttributedString:[RoomBubbleCellData timestampVerticalWhitespace]];
                }
                
                // Append attributed text
                [currentAttributedTextMsg appendAttributedString:componentString];
                
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

- (void)setContainsLastMessage:(BOOL)containsLastMessage
{
    // Check whether there is something to do
    if (_containsLastMessage || containsLastMessage)
    {
        // Update flag
        _containsLastMessage = containsLastMessage;
        
        // Recompute the text message layout
        self.attributedTextMessage = nil;
    }
}

- (void)setHasReadReceipts:(BOOL)hasReadReceipts
{
    // Check whether there is something to do
    if (_hasReadReceipts || hasReadReceipts)
    {
        // Update flag
        _hasReadReceipts = hasReadReceipts;
        
        // Recompute the text message layout
        self.attributedTextMessage = nil;
    }
}

- (void)setSelectedEventId:(NSString *)selectedEventId
{
    // Check whether there is something to do
    if (_selectedEventId || selectedEventId.length)
    { 
        // Update flag
        _selectedEventId = selectedEventId;
        
        // Recompute the text message layout
        self.attributedTextMessage = nil;
    }
}

- (NSInteger)mostRecentComponentIndex
{
    // Update the related component index
    NSInteger mostRecentComponentIndex = NSNotFound;
    
    NSArray *components = self.bubbleComponents;
    NSInteger index = components.count;
    while (index--)
    {
        MXKRoomBubbleComponent *component = components[index];
        if (component.date)
        {
            mostRecentComponentIndex = index;
            break;
        }
    }
    
    return mostRecentComponentIndex;
}

- (NSInteger)selectedComponentIndex
{
    // Update the related component index
    NSInteger selectedComponentIndex = NSNotFound;
    
    if (_selectedEventId)
    {
        NSArray *components = self.bubbleComponents;
        NSInteger index = components.count;
        while (index--)
        {
            MXKRoomBubbleComponent *component = components[index];
            if ([component.event.eventId isEqualToString:_selectedEventId])
            {
                selectedComponentIndex = index;
                break;
            }
        }
    }
    
    return selectedComponentIndex;
}

#pragma mark -

+ (NSAttributedString *)timestampVerticalWhitespace
{
    @synchronized(self)
    {
        if (timestampVerticalWhitespace == nil)
        {
            timestampVerticalWhitespace = [[NSAttributedString alloc] initWithString:@"\n" attributes:@{NSForegroundColorAttributeName : [UIColor blackColor],
                                                                                                          NSFontAttributeName: [UIFont systemFontOfSize:12]}];
        }
    }
    return timestampVerticalWhitespace;
}


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
