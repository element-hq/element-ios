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
        if (event.eventType == MXEventTypeRoomMember)
        {
            // Membership events have their own cell type
            self.tag = RoomBubbleCellDataTagMembership;

            // Membership events can be collapsed together
            self.collapsable = YES;

            // Collapse them by default
            self.collapsed = YES;
        }
        
        if (event.eventType == MXEventTypeRoomCreate)
        {
            MXRoomCreateContent *createContent = [MXRoomCreateContent modelFromJSON:event.content];
            
            if (createContent.roomPredecessorInfo)
            {
                self.tag = RoomBubbleCellDataTagRoomCreateWithPredecessor;
            }
        }

        // Increase maximum number of components
        self.maxComponentCount = 20;
        
        // Initialize read receipts
        self.readReceipts = [NSMutableDictionary dictionary];
        self.readReceipts[event.eventId] = [roomDataSource.room getEventReceipts:event.eventId sorted:YES];

        // Reset attributedTextMessage to force reset MXKRoomCellData parameters
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
        if (self.hasAttributedTextMessage && !attributedTextMessage.length)
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

#pragma mark - Bubble collapsing

- (BOOL)collapseWith:(id<MXKRoomBubbleCellDataStoring>)cellData
{
    if (self.tag == RoomBubbleCellDataTagMembership
        && cellData.tag == RoomBubbleCellDataTagMembership)
    {
        // For now, do not merge VoIP conference events
        if (![MXCallManager isConferenceUser:cellData.events.firstObject.stateKey])
        {
            // Keep a pagination between events of different days
            NSString *bubbleDateString = [roomDataSource.eventFormatter dateStringFromDate:self.date withTime:NO];
            NSString *eventDateString = [roomDataSource.eventFormatter dateStringFromDate:((RoomBubbleCellData*)cellData).date withTime:NO];
            if (bubbleDateString && eventDateString && [bubbleDateString isEqualToString:eventDateString])
            {
                return YES;
            }
        }

        return NO;
    }
    
    if (self.tag == RoomBubbleCellDataTagRoomCreateWithPredecessor || cellData.tag == RoomBubbleCellDataTagRoomCreateWithPredecessor)
    {
        return NO;
    }
    
    return [super collapseWith:cellData];
}

- (void)setCollapsed:(BOOL)collapsed
{
    if (collapsed != self.collapsed)
    {
        super.collapsed = collapsed;

        // Refresh only cells series header
        if (self.collapsedAttributedTextMessage && self.nextCollapsableCellData)
        {
            attributedTextMessage = nil;
        }
    }
}

#pragma mark - 

- (NSAttributedString*)refreshAttributedTextMessage
{
    // CAUTION: This method must be called on the main thread.

    // Return the collapsed string only for cells series header
    if (self.collapsed && self.collapsedAttributedTextMessage && self.nextCollapsableCellData)
    {
        return super.collapsedAttributedTextMessage;
    }

    NSMutableAttributedString *currentAttributedTextMsg;
    
    NSInteger selectedComponentIndex = self.selectedComponentIndex;
    NSInteger lastMessageIndex = self.containsLastMessage ? self.mostRecentComponentIndex : NSNotFound;
    
    MXKRoomBubbleComponent *component;
    NSAttributedString *componentString;
    NSUInteger index = 0;
    for (; index < bubbleComponents.count; index++)
    {
        component = bubbleComponents[index];
        componentString = component.attributedTextMessage;
        
        if (componentString)
        {
            // Check whether another component than this one is selected
            // Note: When a component is selected, it is highlighted by applying an alpha on other components.
            if (selectedComponentIndex != NSNotFound && selectedComponentIndex != index && componentString.length)
            {
                // Apply alpha to blur this component
                NSMutableAttributedString *customComponentString = [[NSMutableAttributedString alloc] initWithAttributedString:componentString];
                UIColor *color = [componentString attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:nil];
                color = [color colorWithAlphaComponent:0.2];
                
                [customComponentString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, customComponentString.length)];
                componentString = customComponentString;
            }
            
            // Check whether the timestamp is displayed for this component, and check whether a vertical whitespace is required
            if ((selectedComponentIndex == index || lastMessageIndex == index) && (self.shouldHideSenderInformation || self.shouldHideSenderName))
            {
                currentAttributedTextMsg = [[NSMutableAttributedString alloc] initWithAttributedString:[RoomBubbleCellData timestampVerticalWhitespace]];
                [currentAttributedTextMsg appendAttributedString:componentString];
            }
            else
            {
                // Init attributed string with the first text component
                currentAttributedTextMsg = [[NSMutableAttributedString alloc] initWithAttributedString:componentString];
            }

            if (self.readReceipts[component.event.eventId].count)
            {
                // Add vertical whitespace in case of read receipts
                [currentAttributedTextMsg appendAttributedString:[RoomBubbleCellData readReceiptVerticalWhitespace]];
            }
            
            // The first non empty component has been handled.
            break;
        }
    }
    
    for (index++; index < bubbleComponents.count; index++)
    {
        component = bubbleComponents[index];
        componentString = component.attributedTextMessage;
        
        if (componentString)
        {
            [currentAttributedTextMsg appendAttributedString:[MXKRoomBubbleCellDataWithAppendingMode messageSeparator]];
            
            // Check whether another component than this one is selected
            if (selectedComponentIndex != NSNotFound && selectedComponentIndex != index && componentString.length)
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
            
            if (self.readReceipts[component.event.eventId].count)
            {
                // Add vertical whitespace in case of read receipts
                [currentAttributedTextMsg appendAttributedString:[RoomBubbleCellData readReceiptVerticalWhitespace]];
            }
        }
    }
    
    return currentAttributedTextMsg;
}

- (void)refreshBubbleComponentsPosition
{
    // CAUTION: This method must be called on the main thread.
    
    @synchronized(bubbleComponents)
    {
        // Check whether there is at least one component.
        if (bubbleComponents.count)
        {
            BOOL hasReadReceipts = NO;

            // Set position of the first component
            CGFloat positionY = (self.attachment == nil || self.attachment.type == MXKAttachmentTypeFile || self.attachment.type == MXKAttachmentTypeAudio) ? MXKROOMBUBBLECELLDATA_TEXTVIEW_DEFAULT_VERTICAL_INSET : 0;
            MXKRoomBubbleComponent *component;
            NSUInteger index = 0;
            for (; index < bubbleComponents.count; index++)
            {
                // Compute the vertical position for next component
                component = [bubbleComponents objectAtIndex:index];
                
                component.position = CGPointMake(0, positionY);
                
                if (component.attributedTextMessage)
                {
                    hasReadReceipts = (self.readReceipts[component.event.eventId].count > 0);
                    break;
                }
            }
            
            // Check whether the position of other components need to be refreshed
            if (!self.attachment && index < bubbleComponents.count)
            {
                NSMutableAttributedString *attributedString;
                NSInteger selectedComponentIndex = self.selectedComponentIndex;
                NSInteger lastMessageIndex = self.containsLastMessage ? self.mostRecentComponentIndex : NSNotFound;
                
                // Check whether the timestamp is displayed for this first component, and check whether a vertical whitespace is required
                if ((selectedComponentIndex == index || lastMessageIndex == index) && (self.shouldHideSenderInformation || self.shouldHideSenderName))
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
                if (hasReadReceipts)
                {
                    [attributedString appendAttributedString:[RoomBubbleCellData readReceiptVerticalWhitespace]];
                }
                
                [attributedString appendAttributedString:[MXKRoomBubbleCellDataWithAppendingMode messageSeparator]];
                
                for (index++; index < bubbleComponents.count; index++)
                {
                    // Compute the vertical position for next component
                    component = [bubbleComponents objectAtIndex:index];
                    
                    if (component.attributedTextMessage)
                    {
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
                        positionY = MXKROOMBUBBLECELLDATA_TEXTVIEW_DEFAULT_VERTICAL_INSET + (cumulatedHeight - [self rawTextHeight:componentString]);
                        
                        component.position = CGPointMake(0, positionY);
                        
                        // Add vertical whitespace in case of read receipts.
                        if (self.readReceipts[component.event.eventId].count)
                        {
                            [attributedString appendAttributedString:[RoomBubbleCellData readReceiptVerticalWhitespace]];
                        }
                        
                        [attributedString appendAttributedString:[MXKRoomBubbleCellDataWithAppendingMode messageSeparator]];
                    }
                    else
                    {
                        component.position = CGPointMake(0, positionY);
                    }
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

- (NSInteger)oldestComponentIndex
{
    // Update the related component index
    NSInteger oldestComponentIndex = NSNotFound;
    
    NSArray *components = self.bubbleComponents;
    NSInteger index = 0;
    while (index < components.count)
    {
        MXKRoomBubbleComponent *component = components[index];
        if (component.attributedTextMessage && component.date)
        {
            oldestComponentIndex = index;
            break;
        }
        index++;
    }
    
    return oldestComponentIndex;
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
        if (component.attributedTextMessage && component.date)
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

- (BOOL)hasSameSenderAsBubbleCellData:(id<MXKRoomBubbleCellDataStoring>)bubbleCellData
{
    if (self.tag == RoomBubbleCellDataTagMembership || bubbleCellData.tag == RoomBubbleCellDataTagMembership)
    {
        // We do not want to merge membership event cells with other cell types
        return NO;
    }
    
    if (self.tag == RoomBubbleCellDataTagRoomCreateWithPredecessor || bubbleCellData.tag == RoomBubbleCellDataTagRoomCreateWithPredecessor)
    {
        // We do not want to merge room create event cells with other cell types
        return NO;
    }

    return [super hasSameSenderAsBubbleCellData:bubbleCellData];
}

- (BOOL)addEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState
{
    if (self.tag == RoomBubbleCellDataTagMembership || event.eventType == MXEventTypeRoomMember)
    {
        // One single bubble per membership event
        return NO;
    }
    
    if (self.tag == RoomBubbleCellDataTagRoomCreateWithPredecessor || event.eventType == MXEventTypeRoomCreate)
    {
        // We do not want to merge room create event cells with other cell types
        return NO;
    }

    // Update read receipts for this bubble
    self.readReceipts[event.eventId] = [roomDataSource.room getEventReceipts:event.eventId sorted:YES];

    return [super addEvent:event andRoomState:roomState];
}

@end
