/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
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

#import "EventFormatter.h"

#import "RiotDesignValues.h"

#import "WidgetManager.h"

@interface EventFormatter ()
{
    /**
     The calendar used to retrieve the today date.
     */
    NSCalendar *calendar;

    /**
     The local time zone
     */
    NSTimeZone *localTimeZone;
}
@end

@implementation EventFormatter

- (NSAttributedString *)attributedStringFromEvent:(MXEvent *)event withRoomState:(MXRoomState *)roomState error:(MXKEventFormatterError *)error
{
    // Build strings for modular widget events
    // TODO: At the moment, we support only jitsi widgets
    if (event.eventType == MXEventTypeCustom
        && [event.type isEqualToString:kWidgetEventTypeString])
    {
        NSString *displayText;

        // Prepare the display name of the sender
        NSString *senderDisplayName = roomState ? [self senderDisplayNameForEvent:event withRoomState:roomState] : event.sender;

        if ([event.content[@"type"] isEqualToString:kWidgetTypeJitsi])
        {
            // This is an alive jitsi widget
            displayText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"event_formatter_jitsi_widget_added", @"Vector", nil), senderDisplayName];
        }
        else if (event.content.count == 0)
        {
            // This is a closed widget
            // Check if it corresponds to a jitsi widget by looking at other state events for
            // this jitsi widget (widget id = event.stateKey).
            for (MXEvent *widgetStateEvent in [roomState stateEventsWithType:kWidgetEventTypeString])
            {
                if ([widgetStateEvent.stateKey isEqualToString:event.stateKey] && [widgetStateEvent.content[@"type"] isEqualToString:kWidgetTypeJitsi])
                {
                    displayText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"event_formatter_jitsi_widget_removed", @"Vector", nil), senderDisplayName];
                    break;
                }
            }
        }

        if (displayText)
        {
            if (error)
            {
                *error = MXKEventFormatterErrorNone;
            }

            // Build the attributed string with the right font and color for the events
            return [self renderString:displayText forEvent:event];
        }
    }

    return [super attributedStringFromEvent:event withRoomState:roomState error:error];
}

- (NSAttributedString*)attributedStringFromEvents:(NSArray<MXEvent*>*)events withRoomState:(MXRoomState*)roomState error:(MXKEventFormatterError*)error
{
    NSString *displayText;

    if (events.count)
    {
        if (events[0].eventType == MXEventTypeRoomMember)
        {
            // This is a series for cells tagged with RoomBubbleCellDataTagMembership
            // TODO: Build a complete summary like Riot-web
            displayText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"event_formatter_member_updates", @"Vector", nil), events.count];
        }
    }

    if (displayText)
    {
        // Build the attributed string with the right font and color for the events
        return [self renderString:displayText forEvent:events[0]];
    }

    return [super attributedStringFromEvents:events withRoomState:roomState error:error];
}

- (instancetype)initWithMatrixSession:(MXSession *)matrixSession
{
    self = [super initWithMatrixSession:matrixSession];
    if (self)
    {
        calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        // Note: NSDate object always shows time according to GMT, so the calendar should be in GMT too.
        calendar.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];

        localTimeZone = [NSTimeZone localTimeZone];
        
        // Use the secondary bg color to set the background color in the default CSS.
        NSUInteger bgColor = [MXKTools rgbValueWithColor:kRiotSecondaryBgColor];
        self.defaultCSS = [NSString stringWithFormat:@" \
                           pre,code { \
                           background-color: #%06lX; \
                           display: inline; \
                           font-family: monospace; \
                           white-space: pre; \
                           -coretext-fontname: Menlo-Regular; \
                           font-size: small; \
                           }", (unsigned long)bgColor];
        
        self.defaultTextColor = kRiotPrimaryTextColor;
        self.subTitleTextColor = kRiotSecondaryTextColor;
        self.prefixTextColor = kRiotSecondaryTextColor;
        self.bingTextColor = kRiotColorPinkRed;
        self.encryptingTextColor = kRiotColorGreen;
        self.sendingTextColor = kRiotSecondaryTextColor;
        self.errorTextColor = kRiotColorRed;
        
        self.defaultTextFont = [UIFont systemFontOfSize:15];
        self.prefixTextFont = [UIFont boldSystemFontOfSize:15];
        if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)])
        {
            self.bingTextFont = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        }
        else
        {
            self.bingTextFont = [UIFont systemFontOfSize:15];
        }
        self.stateEventTextFont = [UIFont italicSystemFontOfSize:15];
        self.callNoticesTextFont = [UIFont italicSystemFontOfSize:15];
        self.encryptedMessagesTextFont = [UIFont italicSystemFontOfSize:15];
        self.emojiOnlyTextFont = [UIFont systemFontOfSize:48];
    }
    return self;
}

- (NSDictionary*)stringAttributesForEventTimestamp
{
    return @{
             NSForegroundColorAttributeName : [UIColor lightGrayColor],
             NSFontAttributeName: [UIFont systemFontOfSize:10]
             };
}

#pragma mark event sender info

- (NSString*)senderAvatarUrlForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState
{
    // Override this method to ignore the identicons defined by default in matrix kit.
    
    // Consider first the avatar url defined in provided room state (Note: this room state is supposed to not take the new event into account)
    NSString *senderAvatarUrl = [roomState memberWithUserId:event.sender].avatarUrl;
    
    // Check whether this avatar url is updated by the current event (This happens in case of new joined member)
    NSString* membership = event.content[@"membership"];
    if (membership && [membership isEqualToString:@"join"] && [event.content[@"avatar_url"] length])
    {
        // Use the actual avatar
        senderAvatarUrl = event.content[@"avatar_url"];
    }
    
    // We ignore non mxc avatar url (The identicons are removed here).
    if (senderAvatarUrl && [senderAvatarUrl hasPrefix:kMXContentUriScheme] == NO)
    {
        senderAvatarUrl = nil;
    }
    
    return senderAvatarUrl;
}


#pragma mark - Timestamp formatting

- (NSString*)dateStringFromDate:(NSDate *)date withTime:(BOOL)time
{
    // Check the provided date
    if (!date)
    {
        return nil;
    }
    
    // Retrieve today date at midnight
    NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:[NSDate date]];
    NSDate *today = [calendar dateFromComponents:components];
    
    NSTimeInterval localZoneOffset = [localTimeZone secondsFromGMT];
    
    NSTimeInterval interval = -[date timeIntervalSinceDate:today] - localZoneOffset;
    
    if (interval > 60*60*24*364)
    {
        [dateFormatter setDateFormat:@"MMM dd yyyy"];
        
        // Ignore time information here
        return [super dateStringFromDate:date withTime:NO];
    }
    else if (interval > 60*60*24*6)
    {
        [dateFormatter setDateFormat:@"MMM dd"];
        
        // Ignore time information here
        return [super dateStringFromDate:date withTime:NO];
    }
    else if (interval > 60*60*24)
    {
        if (time)
        {
            [dateFormatter setDateFormat:@"EEE"];
        }
        else
        {
            [dateFormatter setDateFormat:@"EEEE"];
        }
        
        return [super dateStringFromDate:date withTime:time];
    }
    else if (interval > 0)
    {
        if (time)
        {
            [dateFormatter setDateFormat:nil];
            return [NSString stringWithFormat:@"%@ %@", NSLocalizedStringFromTable(@"yesterday", @"Vector", nil), [super dateStringFromDate:date withTime:YES]];
        }
        return NSLocalizedStringFromTable(@"yesterday", @"Vector", nil);
    }
    else if (interval > - 60*60*24)
    {
        if (time)
        {
            [dateFormatter setDateFormat:nil];
            return [NSString stringWithFormat:@"%@", [super dateStringFromDate:date withTime:YES]];
        }
        return NSLocalizedStringFromTable(@"today", @"Vector", nil);
    }
    else
    {
        // Date in future
        [dateFormatter setDateFormat:@"EEE MMM dd yyyy"];
        return [super dateStringFromDate:date withTime:time];
    }
}

@end
