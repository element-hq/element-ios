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

        // FIXME use the color defined in room settings
        self.bingTextColor = [UIColor colorWithRed:98.0f / 255.0f green:206.0f / 255.0f blue:156.0f / 255.0f alpha:1.0f];
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


#pragma mark - Timestamp formatting

- (NSString*)dateStringFromDate:(NSDate *)date withTime:(BOOL)time
{
    // Retrieve today date at midnight
    NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:[NSDate date]];
    NSDate *today = [calendar dateFromComponents:components];
    
    NSTimeInterval localZoneOffset = [localTimeZone secondsFromGMT];
    
    NSTimeInterval interval = -[date timeIntervalSinceDate:today] - localZoneOffset;
    if (interval > 60*60*24*6)
    {
        [dateFormatter setDateFormat:@"EEE MMM dd yyyy"];
        return [super dateStringFromDate:date withTime:time];
    }
    else if (interval > 60*60*24)
    {
        [dateFormatter setDateFormat:@"EEEE"];
        return [super dateStringFromDate:date withTime:time];
    }
    else if (interval > 0)
    {
        if (time)
        {
            [dateFormatter setDateFormat:nil];
            return [NSString stringWithFormat:@"yesterday %@", [super dateStringFromDate:date withTime:YES]];
        }
        return @"yesterday";
    }
    else if (interval > - 60*60*24)
    {
        if (time)
        {
            [dateFormatter setDateFormat:nil];
            return [NSString stringWithFormat:@"today %@", [super dateStringFromDate:date withTime:YES]];
        }
        return @"today";
    }
    else
    {
        // Date in future
        [dateFormatter setDateFormat:@"EEE MMM dd yyyy"];
        return [super dateStringFromDate:date withTime:time];
    }
}

@end
