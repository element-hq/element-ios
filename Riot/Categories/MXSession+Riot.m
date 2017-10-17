/*
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

#import "MXSession+Riot.h"

#import "MXRoom+Riot.h"

@implementation MXSession (Riot)

- (NSUInteger)riot_missedDiscussionsCount
{
    NSUInteger missedDiscussionsCount = 0;
    
    // Sum all the rooms with missed notifications.
    for (MXRoomSummary *roomSummary in self.roomsSummaries)
    {
        NSUInteger notificationCount = roomSummary.notificationCount;
        
        // Ignore the regular notification count if the room is in 'mentions only" mode at the Riot level.
        if (roomSummary.room.isMentionsOnly)
        {
            // Only the highlighted missed messages must be considered here.
            notificationCount = roomSummary.highlightCount;
        }
        
        if (notificationCount)
        {
            missedDiscussionsCount++;
        }
    }
    
    // Add the invites count
    missedDiscussionsCount += [self invitedRooms].count;
    
    return missedDiscussionsCount;
}

@end
