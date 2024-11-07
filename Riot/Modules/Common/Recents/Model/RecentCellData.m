/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
