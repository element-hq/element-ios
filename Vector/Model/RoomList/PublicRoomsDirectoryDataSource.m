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

#import "PublicRoomsDirectoryDataSource.h"

#import "PublicRoomTableViewCell.h"

#pragma mark - Constants definitions

// Time in seconds from which public rooms data is considered as obsolete
double const kPublicRoomsDirectoryDataExpiration = 10;

#pragma mark - PublicRoomsDirectoryDataSource

@interface PublicRoomsDirectoryDataSource ()
{
    // The pending request to refresh public rooms data.
    MXHTTPOperation *publicRoomsRequest;

    // The date of the last fetched data.
    NSDate *lastRefreshDate;
}

@end

@implementation PublicRoomsDirectoryDataSource

- (void)setSearchPatternsList:(NSArray<NSString *> *)newSearchPatternsList
{
    NSString *searchPatternsListString = [_searchPatternsList componentsJoinedByString:@""];
    NSString *newSearchPatternsListString = [newSearchPatternsList componentsJoinedByString:@""];

    if (![newSearchPatternsListString isEqualToString:searchPatternsListString])
    {
        _searchPatternsList = newSearchPatternsList;
        [self refreshPublicRooms];
    }
}

#pragma mark - Private methods

- (void)refreshPublicRooms
{
    // Do not refresh data if it is not too old
    if (lastRefreshDate && -lastRefreshDate.timeIntervalSinceNow < kPublicRoomsDirectoryDataExpiration)
    {
        // Apply the new filter on the current data
        [self refreshFilteredPublicRooms];

        [self setState:MXKDataSourceStateReady];
    }
    else
    {
        // Cancel the previous request
        if (publicRoomsRequest)
        {
            [publicRoomsRequest cancel];
        }

        [self setState:MXKDataSourceStatePreparing];

        lastRefreshDate = [NSDate date];

        // Get the public rooms from the server
        publicRoomsRequest = [self.mxSession.matrixRestClient publicRooms:^(NSArray *rooms) {

            // Order rooms by their members count
            _rooms = [rooms sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
                      {
                          MXPublicRoom *firstRoom =  (MXPublicRoom*)a;
                          MXPublicRoom *secondRoom = (MXPublicRoom*)b;

                          // Compare member count
                          if (firstRoom.numJoinedMembers < secondRoom.numJoinedMembers)
                          {
                              return NSOrderedDescending;
                          }
                          else if (firstRoom.numJoinedMembers > secondRoom.numJoinedMembers)
                          {
                              return NSOrderedAscending;
                          }
                          else
                          {
                              // Alphabetic order
                              return [firstRoom.displayname compare:secondRoom.displayname options:NSCaseInsensitiveSearch];
                          }
                      }];

            lastRefreshDate = [NSDate date];
            publicRoomsRequest = nil;

            [self refreshFilteredPublicRooms];

            [self setState:MXKDataSourceStateReady];

        } failure:^(NSError *error) {
            NSLog(@"[PublicRoomsDirectoryDataSource] Failed to fecth public rooms. Error: %@", error);
            
            [self setState:MXKDataSourceStateFailed];
        }];
    }
}

- (void)refreshFilteredPublicRooms
{
    // Apply filter if any
    if (_searchPatternsList)
    {
        NSMutableArray *filteredRooms = [NSMutableArray array];
        for (MXPublicRoom *publicRoom in _rooms)
        {
            if ([filteredRooms indexOfObjectIdenticalTo:publicRoom] == NSNotFound)
            {
                // Do a AND search
                BOOL matchAll = YES;
                for (NSString *pattern in _searchPatternsList)
                {
                    if (pattern.length && NO == [publicRoom.displayname localizedCaseInsensitiveContainsString:pattern])
                    {
                        matchAll = NO;
                        break;
                    }
                }

                if (matchAll)
                {
                    [filteredRooms addObject:publicRoom];
                }
            }
        }

        _filteredRooms = filteredRooms;
    }
    else
    {
        _filteredRooms = _rooms;
    }
}


// Update the MXKDataSource state and the delegate
- (void)setState:(MXKDataSourceState)newState
{
    state = newState;
    if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:didStateChange:)])
    {
        [self.delegate dataSource:self didStateChange:state];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _filteredRooms.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // For now reuse MatrixKit cells
    // TODO: use custom cells and manage a mechanism a la MatrixKit with cellData
    PublicRoomTableViewCell *publicRoomCell = [tableView dequeueReusableCellWithIdentifier:[PublicRoomTableViewCell defaultReuseIdentifier]];
    if (!publicRoomCell)
    {
        publicRoomCell = [[PublicRoomTableViewCell alloc] init];
    }

    [publicRoomCell render:_filteredRooms[indexPath.row]];

    return publicRoomCell;
}

@end
