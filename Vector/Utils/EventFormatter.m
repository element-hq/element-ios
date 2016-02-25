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

#import "EventFormatter.h"

#import "VectorDesignValues.h"

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

- (instancetype)initWithMatrixSession:(MXSession *)matrixSession
{
    self = [super initWithMatrixSession:matrixSession];
    if (self)
    {
        calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        // Note: NSDate object always shows time according to GMT, so the calendar should be in GMT too.
        calendar.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];

        localTimeZone = [NSTimeZone localTimeZone];
        
        self.defaultTextColor = kVectorTextColorBlack;
        self.subTitleTextColor = kVectorTextColorGray;
        self.prefixTextColor = kVectorTextColorGray;
        self.bingTextColor = kVectorColorGreen;
        self.sendingTextColor = kVectorTextColorGray;
        self.errorTextColor = kVectorTextColorRed;
        
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
        self.callInviteTextFont = [UIFont italicSystemFontOfSize:15];
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
    if ([event.content[@"avatar_url"] length])
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
