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
        // Increase maximum number of components
        self.maxComponentCount = 20;
        
        // Initialize receipts flag
        _hasReadReceipts = NO;
        
        // Force the update of the text message to take into account the potential read receipts in the bubble display.
        // Note: we don't update this attributed string here because the RoomBubbleCellData instances are created on a processing
        // thread different from the UI thread.
        self.attributedTextMessage = nil;
    }
    
    return self;
}

- (void)prepareBubbleComponentsPosition
{
    if (shouldUpdateComponentsPosition)
    {
        // The bubble layout depends on the room read receipts which must be retrieved on the main thread to prevent us from race conditions.
        // Check here the current thread, this is just a sanity check because this method is called during the rendering step
        // which takes place on the main thread.
        if ([NSThread currentThread] != [NSThread mainThread])
        {
            NSLog(@"[RoomBubbleCellData] prepareBubbleComponentsPosition called on wrong thread");
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self refreshBubbleComponentsPosition];
            });
        }
        else
        {
            [self refreshBubbleComponentsPosition];
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
            // Attributed text message depends on the room read receipts which must be retrieved on the main thread to prevent us from race conditions.
            // Check here the current thread, this is just a sanity check because the attributed text message
            // is requested during the rendering step which takes place on the main thread.
            if ([NSThread currentThread] != [NSThread mainThread])
            {
                NSLog(@"[RoomBubbleCellData] attributedTextMessage called on wrong thread");
                dispatch_sync(dispatch_get_main_queue(), ^{
                    self.attributedTextMessage = [self refreshAttributedTextMessage];
                });
            }
            else
            {
                self.attributedTextMessage = [self refreshAttributedTextMessage];
            }
        }
    }
    
    return attributedTextMessage;
}

#pragma mark - 

- (NSAttributedString*)refreshAttributedTextMessage
{
    // CAUTION: This method must be called on the main thread.
    
    NSMutableAttributedString *currentAttributedTextMsg;
    
    // Refresh the receipt flag during this process
    _hasReadReceipts = NO;
    
    MXKRoomBubbleComponent *component = [bubbleComponents firstObject];
    NSAttributedString *componentString = component.attributedTextMessage;
    
#ifndef DEBUG
    // Sanity check: we observed some app crashes due to a nil string in a component.
    // According to the implementation this case should not happen because the components are removed as soon as their string is nil.
    // We patch here this issue by adding some logs in order to investigate it in the future.
    if (!componentString)
    {
        NSLog(@"[RoomBubbleCellData] WARNING: refreshAttributedTextMessage: unexpected empty component (0/%tu), %@", bubbleComponents.count, component.event.eventId);
        componentString = [[NSAttributedString alloc] initWithString:@""];
    }
#endif
    
    NSInteger selectedComponentIndex = self.selectedComponentIndex;
    NSInteger lastMessageIndex = self.containsLastMessage ? self.mostRecentComponentIndex : NSNotFound;
    
    // Check whether another component than the first one is selected
    // Note: When a component is selected, it is highlighted by applying an alpha on other components.
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
        _hasReadReceipts = YES;
        [currentAttributedTextMsg appendAttributedString:[RoomBubbleCellData readReceiptVerticalWhitespace]];
    }
    
    for (NSUInteger index = 1; index < bubbleComponents.count; index++)
    {
        [currentAttributedTextMsg appendAttributedString:[MXKRoomBubbleCellDataWithAppendingMode messageSeparator]];
        
        component = bubbleComponents[index];
        componentString = component.attributedTextMessage;
        
#ifndef DEBUG
        // Sanity check: we observed some app crashes due to a nil string in a component.
        // According to the implementation this case should not happen because the components are removed as soon as their string is nil.
        // We patch here this issue by adding some logs in order to investigate it in the future.
        if (!componentString)
        {
            NSLog(@"[RoomBubbleCellData] refreshAttributedTextMessage: WARNING: unexpected empty component (%tu/%tu), %@", index, bubbleComponents.count, component.event.eventId);
            componentString = [[NSAttributedString alloc] initWithString:@""];
        }
#endif
        
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
    
    return currentAttributedTextMsg;
}

- (void)refreshBubbleComponentsPosition
{
    // CAUTION: This method must be called on the main thread.
    
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
}

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
