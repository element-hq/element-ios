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

#import "RoomSearchDataSource.h"

#import "RoomBubbleCellData.h"

@interface RoomSearchDataSource ()
{
    MXKRoomDataSource *roomDataSource;
}

@end

@implementation RoomSearchDataSource

- (instancetype)initWithRoomDataSource:(MXKRoomDataSource *)roomDataSource2 andMatrixSession:(MXSession *)mxSession
{
    self = [super initWithRoomId:roomDataSource2.roomId andMatrixSession:mxSession];
    if (self)
    {
        roomDataSource = roomDataSource2;
    }
    return self;
}

- (void)convertHomeserverResultsIntoCells:(MXSearchRoomEventResults *)roomEventResults
{
    // Convert the HS results into `RoomViewController` cells
    for (MXSearchResult *result in roomEventResults.results)
    {
        // Let the `RoomViewController` ecosystem do the job
        // The search result contains only room message events, no state events.
        // Thus, passing the current room state is not a huge problem. Only
        // the user display name and his avatar may be wrong.
        RoomBubbleCellData *cellData = [[RoomBubbleCellData alloc] initWithEvent:result.result andRoomState:roomDataSource.room.state andRoomDataSource:roomDataSource];
        if (cellData)
        {
            [cellDataArray insertObject:cellData atIndex:0];
        }
    }
}

@end
