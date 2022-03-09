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

#import "RecentCellData.h"

#import "MXRoom+Riot.h"

#import "GeneratedInterface-Swift.h"

@implementation RecentCellData

//  Adds K handling to super implementation
- (NSString*)notificationCountStringValue
{
    NSString *stringValue;
    NSUInteger notificationCount = self.notificationCount;
    
    if (notificationCount > 1000)
    {
        CGFloat value = notificationCount / 1000.0;
        stringValue = [VectorL10n largeBadgeValueKFormat:value];
    }
    else
    {
        stringValue = [NSString stringWithFormat:@"%tu", notificationCount];
    }
    
    return stringValue;
}

//  Adds mentions-only handling to super implementation
- (NSUInteger)notificationCount
{
    MXRoom *room = [self.mxSession roomWithRoomId:self.roomSummary.roomId];
    // Ignore the regular notification count if the room is in 'mentions only" mode at the Riot level.
    if (room.isMentionsOnly)
    {
        // Only the highlighted missed messages must be considered here.
        return super.highlightCount;
    }
    
    return super.notificationCount;
}

//  Adds "Empty Room" case to super implementation
- (NSString *)roomDisplayname
{
    NSString *result = [super roomDisplayname];
    if (!result.length)
    {
        result = [VectorL10n roomDisplaynameEmptyRoom];
    }
    return result;
}

@end
