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
        // use the vector style placeholder
        self.senderAvatarPlaceholder = [AvatarGenerator generateRoomMemberAvatar:self.senderId displayName:self.senderDisplayName];
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
        }
    }
    
    return customAttributedTextMsg;
}

@end
