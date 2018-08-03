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

#import "RoomSearchDataSource.h"

#import "RoomBubbleCellData.h"

#import "RiotDesignValues.h"

#import "MXKRoomBubbleTableViewCell+Riot.h"

@interface RoomSearchDataSource ()
{
    MXKRoomDataSource *roomDataSource;
}

@end

@implementation RoomSearchDataSource

- (instancetype)initWithRoomDataSource:(MXKRoomDataSource *)roomDataSource2
{
    self = [super initWithMatrixSession:roomDataSource2.mxSession];
    if (self)
    {
        roomDataSource = roomDataSource2;
        
        // The messages search is limited to the room data.
        self.roomEventFilter.rooms = @[roomDataSource.roomId];
    }
    return self;
}

- (void)destroy
{
    roomDataSource = nil;
    
    [super destroy];
}

- (void)convertHomeserverResultsIntoCells:(MXSearchRoomEventResults *)roomEventResults onComplete:(dispatch_block_t)onComplete
{
    // Prepare text font used to highlight the search pattern.
    UIFont *patternFont = [roomDataSource.eventFormatter bingTextFont];
    
    // Convert the HS results into `RoomViewController` cells
    for (MXSearchResult *result in roomEventResults.results)
    {
        // Let the `RoomViewController` ecosystem do the job
        // The search result contains only room message events, no state events.
        // Thus, passing the current room state is not a huge problem. Only
        // the user display name and his avatar may be wrong.
        RoomBubbleCellData *cellData = [[RoomBubbleCellData alloc] initWithEvent:result.result andRoomState:roomDataSource.roomState andRoomDataSource:roomDataSource];
        if (cellData)
        {
            // Highlight the search pattern
            [cellData highlightPatternInTextMessage:self.searchText withForegroundColor:kRiotColorGreen andFont:patternFont];

            // Use profile information as data to display
            MXSearchUserProfile *userProfile = result.context.profileInfo[result.result.sender];
            cellData.senderDisplayName = userProfile.displayName;
            cellData.senderAvatarUrl = userProfile.avatarUrl;

            [cellDataArray insertObject:cellData atIndex:0];
        }
    }

    onComplete();
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    // Finalize cell view customization here
    if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
    {
        MXKRoomBubbleTableViewCell *bubbleCell = (MXKRoomBubbleTableViewCell*)cell;
        
        // Display date for each message
        [bubbleCell addDateLabel];
    }
    
    return cell;
}

@end
