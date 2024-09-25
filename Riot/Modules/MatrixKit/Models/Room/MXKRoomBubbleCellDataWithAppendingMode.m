/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomBubbleCellDataWithAppendingMode.h"

#import "GeneratedInterface-Swift.h"

static NSAttributedString *messageSeparator = nil;

@implementation MXKRoomBubbleCellDataWithAppendingMode

#pragma mark - MXKRoomBubbleCellDataStoring

- (instancetype)initWithEvent:(MXEvent *)event andRoomState:(MXRoomState *)roomState andRoomDataSource:(MXKRoomDataSource *)roomDataSource
{
    self = [super initWithEvent:event andRoomState:roomState andRoomDataSource:roomDataSource];
    if (self)
    {
        // Set default settings
        self.maxComponentCount = 10;
    }
    
    return self;
}

- (BOOL)addEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState
{
    // We group together text messages from the same user (attachments are not merged).
    if ([event.sender isEqualToString:self.senderId] && (self.attachment == nil) && (self.bubbleComponents.count < self.maxComponentCount))
    {
        // Attachments (image, video, sticker ...) cannot be added here
        if ([roomDataSource.eventFormatter isSupportedAttachment:event])
        {
            return NO;
        }
        
        // Check sender information
        // If `roomScreenUseOnlyLatestUserAvatarAndName`is enabled, the avatar and name are
        // displayed from the latest room state perspective rather than the historical.
        MXRoomState *latestRoomState = roomDataSource.roomState;
        MXRoomState *displayRoomState = RiotSettings.shared.roomScreenUseOnlyLatestUserAvatarAndName ? latestRoomState : roomState;
        NSString *eventSenderName = [roomDataSource.eventFormatter senderDisplayNameForEvent:event withRoomState:displayRoomState];
        NSString *eventSenderAvatar = [roomDataSource.eventFormatter senderAvatarUrlForEvent:event withRoomState:displayRoomState];
        if ((self.senderDisplayName || eventSenderName) &&
            ([self.senderDisplayName isEqualToString:eventSenderName] == NO))
        {
            return NO;
        }
        if ((self.senderAvatarUrl || eventSenderAvatar) &&
            ([self.senderAvatarUrl isEqualToString:eventSenderAvatar] == NO))
        {
            return NO;
        }
        
        // Take into account here the rendered bubbles pagination
        if (roomDataSource.bubblesPagination == MXKRoomDataSourceBubblesPaginationPerDay)
        {
            // Event must be sent the same day than the existing bubble.
            NSString *bubbleDateString = [roomDataSource.eventFormatter dateStringFromDate:self.date withTime:NO];
            NSString *eventDateString = [roomDataSource.eventFormatter dateStringFromEvent:event withTime:NO];
            if (bubbleDateString && eventDateString && ![bubbleDateString isEqualToString:eventDateString])
            {
                return NO;
            }
        }
        
        // Create new message component
        MXKRoomBubbleComponent *addedComponent = [[MXKRoomBubbleComponent alloc] initWithEvent:event
                                                                                     roomState:roomState
                                                                            andLatestRoomState:roomDataSource.roomState
                                                                                eventFormatter:roomDataSource.eventFormatter
                                                                                       session:self.mxSession];
        if (addedComponent)
        {
            [self addComponent:addedComponent];
        }
        // else the event is ignored, we consider it as handled
        return YES;
    }
    return NO;
}

- (BOOL)mergeWithBubbleCellData:(id<MXKRoomBubbleCellDataStoring>)bubbleCellData
{
    if ([self hasSameSenderAsBubbleCellData:bubbleCellData])
    {
        MXKRoomBubbleCellData *cellData = (MXKRoomBubbleCellData*)bubbleCellData;
        // Only text messages are merged (Attachments are not merged).
        if ((self.attachment == nil) && (cellData.attachment == nil))
        {
            // Take into account here the rendered bubbles pagination
            if (roomDataSource.bubblesPagination == MXKRoomDataSourceBubblesPaginationPerDay)
            {
                // bubble components must be sent the same day than self.
                NSString *selfDateString = [roomDataSource.eventFormatter dateStringFromDate:self.date withTime:NO];
                NSString *bubbleDateString = [roomDataSource.eventFormatter dateStringFromDate:bubbleCellData.date withTime:NO];
                if (![bubbleDateString isEqualToString:selfDateString])
                {
                    return NO;
                }
            }
            
            // Add all components of the provided message
            for (MXKRoomBubbleComponent* component in cellData.bubbleComponents)
            {
                [self addComponent:component];
            }
            return YES;
        }
    }
    return NO;
}

- (NSAttributedString*)attributedTextMessageWithHighlightedEvent:(NSString*)eventId tintColor:(UIColor*)tintColor
{
    // Create attributed string
    NSMutableAttributedString *customAttributedTextMsg;
    NSAttributedString *componentString;
    
    @synchronized(bubbleComponents)
    {
        for (MXKRoomBubbleComponent* component in bubbleComponents)
        {
            componentString = component.attributedTextMessage;
            
            if (componentString)
            {
                if ([component.event.eventId isEqualToString:eventId])
                {
                    NSMutableAttributedString *customComponentString = [[NSMutableAttributedString alloc] initWithAttributedString:componentString];
                    UIColor *color = tintColor ? tintColor : [UIColor lightGrayColor];
                    [customComponentString addAttribute:NSBackgroundColorAttributeName value:color range:NSMakeRange(0, customComponentString.length)];
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
            }
        }
    }

    return customAttributedTextMsg;
}

#pragma mark -

- (void)prepareBubbleComponentsPosition
{
    // Set position of the first component
    [super prepareBubbleComponentsPosition];
    
    @synchronized(bubbleComponents)
    {
        // Check whether the position of other components need to be refreshed
        if (!self.attachment && shouldUpdateComponentsPosition && bubbleComponents.count > 1)
        {
            // Init attributed string with the first text component not nil.
            MXKRoomBubbleComponent *component = bubbleComponents.firstObject;
            CGFloat positionY = component.position.y;
            NSMutableAttributedString *attributedString;
            NSUInteger index = 0;
            
            for (; index < bubbleComponents.count; index++)
            {
                component = [bubbleComponents objectAtIndex:index];
                
                component.position = CGPointMake(0, positionY);
                
                if (component.attributedTextMessage)
                {
                    attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:component.attributedTextMessage];
                    [attributedString appendAttributedString:[MXKRoomBubbleCellDataWithAppendingMode messageSeparator]];
                    break;
                }
            }
            
            for (index++; index < bubbleComponents.count; index++)
            {
                // Append the next text component
                component = [bubbleComponents objectAtIndex:index];
                
                if (component.attributedTextMessage)
                {
                    [attributedString appendAttributedString:component.attributedTextMessage];
                    
                    // Compute the height of the resulting string
                    CGFloat cumulatedHeight = [self rawTextHeight:attributedString];
                    
                    // Deduce the position of the beginning of this component
                    CGFloat positionY = MXKROOMBUBBLECELLDATA_TEXTVIEW_DEFAULT_VERTICAL_INSET + (cumulatedHeight - [self rawTextHeight:component.attributedTextMessage]);
                    
                    component.position = CGPointMake(0, positionY);
                    
                    [attributedString appendAttributedString:[MXKRoomBubbleCellDataWithAppendingMode messageSeparator]];
                }
                else
                {
                    // Apply the current vertical position on this empty component.
                    component.position = CGPointMake(0, positionY);
                }
            }
        }
    }
    
    shouldUpdateComponentsPosition = NO;
}

#pragma mark -

- (NSString*)textMessage
{
    NSString *rawText = nil;
    
    if (self.attributedTextMessage)
    {
        // Append all components text message
        NSMutableString *currentTextMsg;
        @synchronized(bubbleComponents)
        {
            for (MXKRoomBubbleComponent* component in bubbleComponents)
            {
                if (component.textMessage == nil)
                {
                    continue;
                }
                if (!currentTextMsg)
                {
                    currentTextMsg = [NSMutableString stringWithString:component.textMessage];
                }
                else
                {
                    // Append text message
                    [currentTextMsg appendString:@"\n"];
                    [currentTextMsg appendString:component.textMessage];
                }
            }
        }
        rawText = currentTextMsg;
    }
    
    return rawText;
}

- (void)setAttributedTextMessage:(NSAttributedString *)inAttributedTextMessage
{
    super.attributedTextMessage = inAttributedTextMessage;

    // Position of each components should be computed again
    shouldUpdateComponentsPosition = YES;
}

- (NSAttributedString*)attributedTextMessage
{
    @synchronized(bubbleComponents)
    {
        if (self.hasAttributedTextMessage && !attributedTextMessage.length)
        {
            // Create attributed string
            NSMutableAttributedString *currentAttributedTextMsg;
            
            for (MXKRoomBubbleComponent* component in bubbleComponents)
            {
                if (component.attributedTextMessage)
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
                }
            }
            self.attributedTextMessage = currentAttributedTextMsg;
        }
    }
    
    return attributedTextMessage;
}

- (void)setMaxTextViewWidth:(CGFloat)inMaxTextViewWidth
{
    CGFloat previousMaxWidth = self.maxTextViewWidth;
    
    [super setMaxTextViewWidth:inMaxTextViewWidth];
    
    // Check change
    if (previousMaxWidth != self.maxTextViewWidth)
    {
        // Position of each components should be computed again
        shouldUpdateComponentsPosition = YES;
    }
}

#pragma mark -

+ (NSAttributedString *)messageSeparator
{
    @synchronized(self)
    {
        if(messageSeparator == nil)
        {
            messageSeparator = [[NSAttributedString alloc] initWithString:@"\n\n" attributes:@{NSForegroundColorAttributeName : [UIColor blackColor],
                                                                                               NSFontAttributeName: [UIFont systemFontOfSize:4]}];
        }
    }
    return messageSeparator;
}

#pragma mark - Privates

- (void)addComponent:(MXKRoomBubbleComponent*)addedComponent
{
    @synchronized(bubbleComponents)
    {
        // Check date of existing components to insert this new one
        NSUInteger index = bubbleComponents.count;
        
        // Component without date is added at the end by default
        if (addedComponent.date)
        {
            while (index)
            {
                MXKRoomBubbleComponent *msgComponent = [bubbleComponents objectAtIndex:(--index)];
                if (msgComponent.date && [msgComponent.date compare:addedComponent.date] != NSOrderedDescending)
                {
                    // New component will be inserted here
                    index ++;
                    break;
                }
            }
        }
        
        // Insert new component
        [bubbleComponents insertObject:addedComponent atIndex:index];
        
        // Indicate that the data's text message layout should be recomputed.
        [self invalidateTextLayout];
    }
}

@end
