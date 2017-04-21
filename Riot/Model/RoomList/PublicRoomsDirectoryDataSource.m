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

#import "PublicRoomsDirectoryDataSource.h"

#import "PublicRoomTableViewCell.h"

#import "AppDelegate.h"

#pragma mark - Constants definitions

// Time in seconds from which public rooms data is considered as obsolete
double const kPublicRoomsDirectoryDataExpiration = 10;

#pragma mark - PublicRoomsDirectoryDataSource

@interface PublicRoomsDirectoryDataSource ()
{
    // The pending request to refresh public rooms data.
    MXHTTPOperation *publicRoomsRequest;

    /**
     All public rooms fetched so far.
     */
    NSMutableArray<MXPublicRoom*> *rooms;

    /**
     The next token to use for pagination.
     */
    NSString *nextBatch;
}

@end

@implementation PublicRoomsDirectoryDataSource

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        rooms = [NSMutableArray array];
        _paginationLimit = 20;
    }
    return self;
}

- (NSString *)directoryServerDisplayname
{
    NSString *directoryServerDisplayname;

    if (_homeserver)
    {
        directoryServerDisplayname = _homeserver;
    }
    else if (_thirdpartyProtocolInstance)
    {
        directoryServerDisplayname = _thirdpartyProtocolInstance.desc;
    }
    else
    {
        directoryServerDisplayname = self.mxSession.matrixRestClient.credentials.homeServer;
    }

    return directoryServerDisplayname;
}

- (void)setHomeserver:(NSString *)homeserver
{
    if (homeserver != _homeserver)
    {
        _homeserver = homeserver;
        _thirdpartyProtocolInstance = nil;

        // Reset data
        [self startPagination];
    }
}

- (void)setThirdpartyProtocolInstance:(MXThirdPartyProtocolInstance *)thirdpartyProtocolInstance
{
    if (thirdpartyProtocolInstance != _thirdpartyProtocolInstance)
    {
        _homeserver = nil;
        _thirdpartyProtocolInstance = thirdpartyProtocolInstance;

        // Reset data
        [self startPagination];
    }
}

- (void)setSearchPattern:(NSString *)searchPattern
{
    if (searchPattern)
    {
        if (![searchPattern isEqualToString:_searchPattern])
        {
            _searchPattern = searchPattern;
            [self startPagination];
        }
    }
    else
    {
        // Refresh if the previous search was not nil
        // or if it is the first time we make a search
        if (_searchPattern || rooms.count == 0)
        {
            _searchPattern = searchPattern;
            [self startPagination];
        }
    }
}

- (NSIndexPath*)cellIndexPathWithRoomId:(NSString*)roomId andMatrixSession:(MXSession*)matrixSession
{
    NSIndexPath *indexPath = nil;

    // Look for the public room
    for (NSInteger index = 0; index < rooms.count; index ++)
    {
        MXPublicRoom *room = rooms[index];
        if ([roomId isEqualToString:room.roomId])
        {
            // Got it
            indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            break;
        }
    }

    return indexPath;
}

- (MXPublicRoom *)roomAtIndexPath:(NSIndexPath *)indexPath
{
    MXPublicRoom *room;

    if (indexPath.row < rooms.count)
    {
        room = rooms[indexPath.row];
    }

    return room;
}

- (void)startPagination
{
    // Cancel the previous request
    if (publicRoomsRequest)
    {
        [publicRoomsRequest cancel];
    }

    [self setState:MXKDataSourceStatePreparing];

    // Reset all pagination vars
    [rooms removeAllObjects];
    nextBatch = nil;
    _roomsCount = 0;
    _moreThanRoomsCount = NO;
    _hasReachedPaginationEnd = NO;

    // And do a single pagination
    [self paginate:nil failure:nil];
}

- (MXHTTPOperation *)paginate:(void (^)(NSUInteger))complete failure:(void (^)(NSError *))failure
{
    if (_hasReachedPaginationEnd)
    {
        return nil;
    }

    __weak typeof(self) weakSelf = self;

    // Get the public rooms from the server
    MXHTTPOperation *newPublicRoomsRequest;
    newPublicRoomsRequest = [self.mxSession.matrixRestClient publicRoomsOnServer:_homeserver limit:_paginationLimit since:nextBatch filter:_searchPattern thirdPartyInstanceId:_thirdpartyProtocolInstance.instanceId includeAllNetworks:NO success:^(MXPublicRoomsResponse *publicRoomsResponse) {

        if (weakSelf)
        {
            typeof(self) self = weakSelf;

            self->publicRoomsRequest = nil;

            [self->rooms addObjectsFromArray:publicRoomsResponse.chunk];
            self->nextBatch = publicRoomsResponse.nextBatch;

            if (!self->_searchPattern)
            {
                // When there is no search, we can use totalRoomCountEstimate returned by the server
                self->_roomsCount = publicRoomsResponse.totalRoomCountEstimate;
                self->_moreThanRoomsCount = NO;
            }
            else
            {
                // Else we can only display something like ">20 matching rooms"
                self->_roomsCount = self->rooms.count;
                self->_moreThanRoomsCount = publicRoomsResponse.nextBatch ? YES : NO;
            }

            // Detect pagination end
            if (!publicRoomsResponse.nextBatch)
            {
                _hasReachedPaginationEnd = YES;
            }

            [self setState:MXKDataSourceStateReady];

            if (complete)
            {
                complete(publicRoomsResponse.chunk.count);
            }
        }

    } failure:^(NSError *error) {

        if (weakSelf)
        {
            typeof(self) self = weakSelf;

            if (!newPublicRoomsRequest || newPublicRoomsRequest.isCancelled)
            {
                // Do not take into account error coming from a cancellation
                return;
            }

            self->publicRoomsRequest = nil;

            NSLog(@"[PublicRoomsDirectoryDataSource] Failed to fecth public rooms.");

            [self setState:MXKDataSourceStateFailed];

            // Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];

            if (failure)
            {
                failure(error);
            }
        }
    }];

    publicRoomsRequest = newPublicRoomsRequest;

    return publicRoomsRequest;
}

#pragma mark - Private methods

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
    return rooms.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // For now reuse MatrixKit cells
    PublicRoomTableViewCell *publicRoomCell = [tableView dequeueReusableCellWithIdentifier:[PublicRoomTableViewCell defaultReuseIdentifier]];
    if (!publicRoomCell)
    {
        publicRoomCell = [[PublicRoomTableViewCell alloc] init];
    }
    
    // Sanity check
    if (indexPath.row < rooms.count)
    {
        [publicRoomCell render:rooms[indexPath.row] withMatrixSession:self.mxSession];
    }

    return publicRoomCell;
}

@end
