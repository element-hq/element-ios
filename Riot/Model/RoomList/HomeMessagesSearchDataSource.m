/*
 Copyright 2016 OpenMarket Ltd
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

#import "HomeMessagesSearchDataSource.h"

#import "RoomBubbleCellData.h"

#import "RiotDesignValues.h"

#import "MXKRoomBubbleTableViewCell+Riot.h"

@implementation HomeMessagesSearchDataSource

- (void)destroy
{
    [super destroy];
}

- (void)convertHomeserverResultsIntoCells:(MXSearchRoomEventResults *)roomEventResults
{
    MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:self.mxSession];
    
    // Convert the HS results into `RoomViewController` cells
    for (MXSearchResult *result in roomEventResults.results)
    {
        // Retrieve the local room data source thanks to the room identifier
        // Note: if no local room data source exist the result is ignored.
        NSString *roomId = result.result.roomId;
        UIFont *patternFont = nil;
        MXKRoomDataSource *roomDataSource;
        if (roomId)
        {
            roomDataSource = [roomDataSourceManager roomDataSourceForRoom:roomId create:NO];
            
            if (roomDataSource)
            {
                // Prepare text font used to highlight the search pattern.
                patternFont = [roomDataSource.eventFormatter bingTextFont];
                
                // Let the `RoomViewController` ecosystem do the job
                // The search result contains only room message events, no state events.
                // Thus, passing the current room state is not a huge problem. Only
                // the user display name and his avatar may be wrong.
                RoomBubbleCellData *cellData = [[RoomBubbleCellData alloc] initWithEvent:result.result andRoomState:roomDataSource.room.state andRoomDataSource:roomDataSource];
                if (cellData)
                {
                    // Highlight the search pattern
                    [cellData highlightPatternInTextMessage:self.searchText withForegroundColor:kRiotColorGreen andFont:patternFont];
                    
                    [cellDataArray insertObject:cellData atIndex:0];
                }
            }
        }
    }
    
    // In case of successive messages from the same room,
    // we use the pagination flag to display the room name only on the first message.
    NSString *currentRoomId;
    for (RoomBubbleCellData *cellData in cellDataArray)
    {
        if (currentRoomId && [currentRoomId isEqualToString:cellData.roomId])
        {
            cellData.isPaginationFirstBubble = NO;
        }
        else
        {
            cellData.isPaginationFirstBubble = YES;
            currentRoomId = cellData.roomId;
        }
    }
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
