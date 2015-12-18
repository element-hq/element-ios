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

@interface PublicRoomsDirectoryDataSource ()
{
    // The pending request to refresh public rooms data.
    MXHTTPOperation *publicRoomsRequest;

    // TODO
    //NSDate *lastRefreshDate;
}

@end

@implementation PublicRoomsDirectoryDataSource

- (void)setSearchPattern:(NSString *)searchTerm
{
    if ([searchTerm isEqualToString:_searchPattern])
    {
        return;
    }

    _searchPattern = searchTerm;
    [self refreshPublicRooms];
}

#pragma mark - Private methods

- (void)refreshPublicRooms
{
    // Cancel the previous request
    if (publicRoomsRequest)
    {
        [publicRoomsRequest cancel];
    }

    [self setState:MXKDataSourceStatePreparing];

    publicRoomsRequest = [self.mxSession.matrixRestClient publicRooms:^(NSArray *rooms) {

        publicRoomsRequest = nil;

        // Apply filter if any
        if (_searchPattern)
        {
            NSMutableArray *matchingRooms = [NSMutableArray array];
            for (MXPublicRoom *publicRoom in rooms)
            {
                if ([matchingRooms indexOfObject:publicRoom] == NSNotFound)
                {
                    if ([publicRoom.displayname rangeOfString:_searchPattern options:NSCaseInsensitiveSearch].location != NSNotFound)
                    {
                        [matchingRooms addObject:publicRoom];
                    }
                }
            }

            _rooms = matchingRooms;
        }
        else
        {
            _rooms = rooms;
        }

        [self setState:MXKDataSourceStateReady];

    } failure:^(NSError *error) {
        NSLog(@"[PublicRoomsDirectoryDataSource] Failed to fecth public rooms. Error: %@", error);

        [self setState:MXKDataSourceStateFailed];
    }];
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

@end
