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

@implementation RoomBubbleCellData

#pragma mark -

- (instancetype)initWithEvent:(MXEvent *)event andRoomState:(MXRoomState *)roomState andRoomDataSource:(MXKRoomDataSource *)roomDataSource2
{
    self = [super initWithEvent:event andRoomState:roomState andRoomDataSource:roomDataSource2];
    
    if (self)
    {
        // use the matrix style placeholder
        self.senderAvatarPlaceholder = [AvatarGenerator generateRoomMemberAvatar:self.senderId displayName:self.senderDisplayName];
    }
    
    return self;
}

- (NSAttributedString*)attributedTextMessage
{
    if (!attributedTextMessage.length && bubbleComponents.count)
    {
        if (super.showBubbleDateTime == NO)
        {
            return super.attributedTextMessage;
        }
        else
        {
            // Create attributed string by adding each component timestamp
            NSMutableAttributedString *currentAttributedTextMsg;
            NSAttributedString *dateTimeAttributedStr;
            NSDictionary *attributes;
            if ([self.eventFormatter isKindOfClass:[EventFormatter class]])
            {
                attributes = [(EventFormatter*)self.eventFormatter stringAttributesForEventTimestamp];
            }
            
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
                
                // Append component timestamp
                NSString *dateTimeStr = [NSString stringWithFormat:@" %@", [self.eventFormatter dateStringFromDate:component.date withTime:YES]];
                if (attributes)
                {
                    dateTimeAttributedStr = [[NSAttributedString alloc] initWithString:dateTimeStr attributes:attributes];
                }
                else
                {
                    dateTimeAttributedStr = [[NSAttributedString alloc] initWithString:dateTimeStr];
                }
                [currentAttributedTextMsg appendAttributedString:dateTimeAttributedStr];
            }
            
            attributedTextMessage = currentAttributedTextMsg;
        }
    }
    
    return attributedTextMessage;
}

- (void)setShowBubbleDateTime:(BOOL)showBubbleDateTime
{
    if (super.showBubbleDateTime != showBubbleDateTime)
    {
        super.showBubbleDateTime = showBubbleDateTime;
        
        // Attributed string must be rebuilt
        self.attributedTextMessage = nil;
    }
}

#pragma mark -

- (void)prepareBubbleComponentsPosition
{
    if (super.showBubbleDateTime == NO)
    {
        [super prepareBubbleComponentsPosition];
    }
    else
    {
        // We will let super prepare only the first component position by disabling shouldUpdateComponentsPosition flag
        BOOL savedShouldUpdateComponentsPosition = shouldUpdateComponentsPosition;
        shouldUpdateComponentsPosition = NO;
        
        [super prepareBubbleComponentsPosition];
        
        // Check whether the position of other components need to be refreshed
        if (self.attachment || !savedShouldUpdateComponentsPosition || bubbleComponents.count < 2)
        {
            return;
        }
        
        // Compute height of the first text component by considering displayed timestamp
        NSAttributedString *dateTimeAttributedStr;
        NSDictionary *attributes;
        if ([self.eventFormatter isKindOfClass:[EventFormatter class]])
        {
            attributes = [(EventFormatter*)self.eventFormatter stringAttributesForEventTimestamp];
        }
        
        MXKRoomBubbleComponent *component = [bubbleComponents firstObject];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:component.attributedTextMessage];
        // Append component timestamp
        NSString *dateTimeStr = [NSString stringWithFormat:@" %@", [self.eventFormatter dateStringFromDate:component.date withTime:YES]];
        if (attributes)
        {
            dateTimeAttributedStr = [[NSAttributedString alloc] initWithString:dateTimeStr attributes:attributes];
        }
        else
        {
            dateTimeAttributedStr = [[NSAttributedString alloc] initWithString:dateTimeStr];
        }
        [attributedString appendAttributedString:dateTimeAttributedStr];
        
        CGFloat componentHeight = [self rawTextHeight:attributedString];
        
        // Set position for each other component
        CGFloat positionY = component.position.y;
        CGFloat cumulatedHeight = 0;
        
        for (NSUInteger index = 1; index < bubbleComponents.count; index++)
        {
            cumulatedHeight += componentHeight;
            positionY += componentHeight;
            
            component = [bubbleComponents objectAtIndex:index];
            component.position = CGPointMake(0, positionY);
            
            // Compute height of the current component
            [attributedString appendAttributedString:[MXKRoomBubbleCellDataWithAppendingMode messageSeparator]];
            [attributedString appendAttributedString:component.attributedTextMessage];
            
            dateTimeStr = [NSString stringWithFormat:@" %@", [self.eventFormatter dateStringFromDate:component.date withTime:YES]];
            if (attributes)
            {
                dateTimeAttributedStr = [[NSAttributedString alloc] initWithString:dateTimeStr attributes:attributes];
            }
            else
            {
                dateTimeAttributedStr = [[NSAttributedString alloc] initWithString:dateTimeStr];
            }
            [attributedString appendAttributedString:dateTimeAttributedStr];
            
            componentHeight = [self rawTextHeight:attributedString] - cumulatedHeight;
        }
    }
}

@end
