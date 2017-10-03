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

        Widget *widget = [[Widget alloc] initWithWidgetEvent:event inMatrixSession:mxSession];
        if (widget)
        {
            // Prepare the display name of the sender
            NSString *senderDisplayName = roomState ? [self senderDisplayNameForEvent:event withRoomState:roomState] : event.sender;

            if (widget.isActive)
            {
                if ([widget.type isEqualToString:kWidgetTypeJitsi])
                {
                    // This is an alive jitsi widget
                    displayText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"event_formatter_jitsi_widget_added", @"Vector", nil), senderDisplayName];
                }
                else
                {
                    displayText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"event_formatter_widget_added", @"Vector", nil),
                                   widget.name ? widget.name : widget.type,
                                   senderDisplayName];
                }
            }
            else
            {
                // This is a closed widget
                // Check if it corresponds to a jitsi widget by looking at other state events for
                // this jitsi widget (widget id = event.stateKey).
                for (MXEvent *widgetStateEvent in [roomState stateEventsWithType:kWidgetEventTypeString])
                {
                    if ([widgetStateEvent.stateKey isEqualToString:widget.widgetId])
                    {
                        Widget *activeWidget = [[Widget alloc] initWithWidgetEvent:widgetStateEvent inMatrixSession:mxSession];
                        if (activeWidget.isActive)
                        {
                            if ([activeWidget.type isEqualToString:kWidgetTypeJitsi])
                            {
                                // This was a jitsi widget
                                displayText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"event_formatter_jitsi_widget_removed", @"Vector", nil), senderDisplayName];
                            }
                            else
                            {
                                displayText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"event_formatter_widget_removed", @"Vector", nil),
                                               activeWidget.name ? activeWidget.name : activeWidget.type,
                                               senderDisplayName];
                            }
                            break;
                        }
                    }
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

#pragma mark - MXRoomSummaryUpdating

- (BOOL)session:(MXSession *)session updateRoomSummary:(MXRoomSummary *)summary withStateEvents:(NSArray<MXEvent *> *)stateEvents
{
    BOOL ret = [super session:session updateRoomSummary:summary withStateEvents:stateEvents];
    
    // Check whether the room display name and/or the room avatar url should be updated at Riot level.
    NSString *riotRoomDisplayName;
    NSString *riotRoomAvatarURL;
    
    for (MXEvent *event in stateEvents)
    {
        switch (event.eventType)
        {
            case MXEventTypeRoomName:
            case MXEventTypeRoomAliases:
            case MXEventTypeRoomCanonicalAlias:
            {
                if (!riotRoomDisplayName.length)
                {
                    riotRoomDisplayName = [self riotRoomDisplayNameFromRoomState:summary.room.state];
                }
                break;
            }
            case MXEventTypeRoomMember:
            {
                if (!riotRoomDisplayName.length)
                {
                    riotRoomDisplayName = [self riotRoomDisplayNameFromRoomState:summary.room.state];
                }
                // Do not break here to check avatar url too.
            }
            case MXEventTypeRoomAvatar:
            {
                if (!riotRoomAvatarURL.length)
                {
                    riotRoomAvatarURL = [self riotRoomAvatarURLFromRoomState:summary.room.state];
                }
                break;
            }
            default:
                break;
        }
    }
    
    if (riotRoomDisplayName.length && ![summary.displayname isEqualToString:riotRoomDisplayName])
    {
        summary.displayname = riotRoomDisplayName;
        ret = YES;
    }
    
    if (riotRoomAvatarURL.length && ![summary.avatar isEqualToString:riotRoomAvatarURL])
    {
        summary.avatar = riotRoomAvatarURL;
        ret = YES;
    }
    
    return ret;
}

#pragma mark - Riot room display name

- (NSString *)riotRoomDisplayNameFromRoomState:(MXRoomState *)roomState
{
    // this algo is the one defined in
    // https://github.com/matrix-org/matrix-js-sdk/blob/develop/lib/models/room.js#L617
    // calculateRoomName(room, userId)
    
    // This display name is @"" for an "empty room" without display name (We name "empty room" a room in which the current user is the only active member).
    
    if (roomState.name.length > 0)
    {
        return roomState.name;
    }
    
    NSString *alias = roomState.canonicalAlias;
    
    if (!alias)
    {
        // For rooms where canonical alias is not defined, we use the 1st alias as a workaround
        NSArray *aliases = roomState.aliases;
        
        if (aliases.count)
        {
            alias = [aliases[0] copy];
        }
    }
    
    // check if there is non empty alias.
    if ([alias length] > 0)
    {
        return alias;
    }
    
    NSString* myUserId = mxSession.myUser.userId;
    
    NSArray* members = roomState.members;
    NSMutableArray* othersActiveMembers = [[NSMutableArray alloc] init];
    NSMutableArray* activeMembers = [[NSMutableArray alloc] init];
    
    for(MXRoomMember* member in members)
    {
        if (member.membership != MXMembershipLeave)
        {
            if (![member.userId isEqualToString:myUserId])
            {
                [othersActiveMembers addObject:member];
            }
            
            [activeMembers addObject:member];
        }
    }
    
    // sort the members by their creation (oldest first)
    othersActiveMembers = [[othersActiveMembers sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        
        uint64_t originServerTs1 = 0;
        uint64_t originServerTs2 = 0;
        
        MXRoomMember* member1 = (MXRoomMember*)obj1;
        MXRoomMember* member2 = (MXRoomMember*)obj2;
        
        if (member1.originalEvent)
        {
            originServerTs1 = member1.originalEvent.originServerTs;
        }
        
        if (member2.originalEvent)
        {
            originServerTs2 = member2.originalEvent.originServerTs;
        }
        
        if (originServerTs1 == originServerTs2)
        {
            return NSOrderedSame;
        }
        else
        {
            return originServerTs1 > originServerTs2 ? NSOrderedDescending : NSOrderedAscending;
        }
    }] mutableCopy];
    
    
    NSString* displayName = @"";
    
    if (othersActiveMembers.count == 0)
    {
        if (activeMembers.count == 1)
        {
            MXRoomMember* member = [activeMembers objectAtIndex:0];
            
            if (member.membership == MXMembershipInvite)
            {
                if (member.originalEvent.sender)
                {
                    // extract who invited us to the room
                    displayName = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_displayname_invite_from", @"Vector", nil), [roomState memberName:member.originalEvent.sender]];
                }
                else
                {
                    displayName = NSLocalizedStringFromTable(@"room_displayname_room_invite", @"Vector", nil);
                }
            }
        }
    }
    else if (othersActiveMembers.count == 1)
    {
        MXRoomMember* member = [othersActiveMembers objectAtIndex:0];
        
        displayName = [roomState memberName:member.userId];
    }
    else if (othersActiveMembers.count == 2)
    {
        MXRoomMember* member1 = [othersActiveMembers objectAtIndex:0];
        MXRoomMember* member2 = [othersActiveMembers objectAtIndex:1];
        
        displayName = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_displayname_two_members", @"Vector", nil), [roomState memberName:member1.userId], [roomState memberName:member2.userId]];
    }
    else
    {
        MXRoomMember* member = [othersActiveMembers objectAtIndex:0];
        displayName = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_displayname_more_than_two_members", @"Vector", nil), [roomState memberName:member.userId], othersActiveMembers.count - 1];
    }
    
    return displayName;
}

#pragma mark - Riot room avatar url

- (NSString *)riotRoomAvatarURLFromRoomState:(MXRoomState *)roomState
{
    NSString* roomAvatarUrl = roomState.avatar;
    
    if (!roomAvatarUrl)
    {
        // If the room has only two members, use the avatar of the second member.
        NSArray* members = roomState.members;
        
        if (members.count == 2)
        {
            NSString* myUserId = mxSession.myUser.userId;
            
            for (MXRoomMember *roomMember in members)
            {
                if (![roomMember.userId isEqualToString:myUserId])
                {
                    // Use the avatar of this member only if he joined or he is invited.
                    if (MXMembershipJoin == roomMember.membership || MXMembershipInvite == roomMember.membership)
                    {
                        roomAvatarUrl = roomMember.avatarUrl;
                    }
                    break;
                }
            }
        }
    }
    
    return roomAvatarUrl;
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
