/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "PublicRoomsDirectoryDataSource.h"

#import "PublicRoomTableViewCell.h"

#import "GeneratedInterface-Swift.h"

#pragma mark - Constants definitions

// Time in seconds from which public rooms data is considered as obsolete
double const kPublicRoomsDirectoryDataExpiration = 10;

static NSString *const kNSFWKeyword = @"nsfw";

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

@property (nonatomic, strong) NSRegularExpression *forbiddenTermsRegex;

@end

@implementation PublicRoomsDirectoryDataSource

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        rooms = [NSMutableArray array];
        _paginationLimit = 20;
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"forbidden_terms" ofType:@"txt"];
        NSString *fileContents = [NSString stringWithContentsOfFile:path encoding: NSUTF8StringEncoding error:nil];
        NSArray *forbiddenTerms = [fileContents componentsSeparatedByCharactersInSet: NSCharacterSet.whitespaceAndNewlineCharacterSet];
        
        NSString *pattern = [NSString stringWithFormat:@"\\b(%@)\\b", [forbiddenTerms componentsJoinedByString:@"|"]];
        pattern = [pattern stringByAppendingString:@"|(\\b18\\+)"]; // Special case "18+"
        
        _forbiddenTermsRegex = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
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
        if (_includeAllNetworks)
        {
            // We display all rooms, included bridged ones, of the user's HS
            directoryServerDisplayname = self.mxSession.matrixRestClient.credentials.homeServerName;
        }
        else
        {
            // We display only Matrix rooms of the user's HS
            directoryServerDisplayname = [VectorL10n matrix];
        }
    }

    return directoryServerDisplayname;
}

- (void)setHomeserver:(NSString *)homeserver
{
    if ([homeserver isEqualToString:self.mxSession.matrixRestClient.credentials.homeServerName])
    {
        // The CS API does not like we pass the user's HS as parameter
        homeserver = nil;
    }

     _thirdpartyProtocolInstance = nil;

    if (homeserver != _homeserver)
    {
        _homeserver = homeserver;

        // Reset data
        [self resetPagination];
    }
}

- (void)setIncludeAllNetworks:(BOOL)includeAllNetworks
{
    if (includeAllNetworks != _includeAllNetworks)
    {
        _includeAllNetworks = includeAllNetworks;
        
        // Reset data
        [self resetPagination];
    }
}

- (void)setThirdpartyProtocolInstance:(MXThirdPartyProtocolInstance *)thirdpartyProtocolInstance
{
    if (thirdpartyProtocolInstance != _thirdpartyProtocolInstance)
    {
        _homeserver = nil;
        _includeAllNetworks = NO;
        _thirdpartyProtocolInstance = thirdpartyProtocolInstance;

        // Reset data
        [self resetPagination];
    }
}

- (void)setSearchPattern:(NSString *)searchPattern
{
    if (searchPattern)
    {
        if (![searchPattern isEqualToString:_searchPattern])
        {
            _searchPattern = searchPattern;
            [self resetPagination];
        }
    }
    else
    {
        // Refresh if the previous search was not nil
        // or if it is the first time we make a search
        if (_searchPattern || rooms.count == 0)
        {
            _searchPattern = searchPattern;
            [self resetPagination];
        }
    }
}

- (NSUInteger)roomsCount
{
    return rooms.count;
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

- (CGFloat)cellHeightAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.row < rooms.count)
    {
        return PublicRoomTableViewCell.cellHeight;
    }
    
    return 50.0;
}

- (void)resetPagination
{
    // Cancel the previous request
    if (publicRoomsRequest)
    {
        [publicRoomsRequest cancel];
    }

    // Reset all pagination vars
    [rooms removeAllObjects];
    nextBatch = nil;
    _searchResultsCount = 0;
    _searchResultsCountIsLimited = NO;
    _hasReachedPaginationEnd = NO;
}

- (MXHTTPOperation *)paginate:(void (^)(NSUInteger))complete failure:(void (^)(NSError *))failure
{
    if (_hasReachedPaginationEnd)
    {
        if (complete)
        {
            complete(0);
        }
        return nil;
    }

    [self setState:MXKDataSourceStatePreparing];

    __weak typeof(self) weakSelf = self;

    // Get the public rooms from the server
    MXHTTPOperation *newPublicRoomsRequest;
    newPublicRoomsRequest = [self.mxSession.matrixRestClient publicRoomsOnServer:_homeserver limit:_paginationLimit since:nextBatch filter:_searchPattern thirdPartyInstanceId:_thirdpartyProtocolInstance.instanceId includeAllNetworks:_includeAllNetworks success:^(MXPublicRoomsResponse *publicRoomsResponse) {

        if (weakSelf)
        {
            typeof(self) self = weakSelf;

            self->publicRoomsRequest = nil;
            
            NSArray<MXPublicRoom*> *publicRooms;
            
            publicRooms = [self filterPublicRooms:publicRoomsResponse.chunk];

            [self->rooms addObjectsFromArray:publicRooms];
            self->nextBatch = publicRoomsResponse.nextBatch;

            if (!self->_searchPattern)
            {
                // When there is no search, we can use totalRoomCountEstimate returned by the server
                self->_searchResultsCount = publicRoomsResponse.totalRoomCountEstimate;
                self->_searchResultsCountIsLimited = NO;
            }
            else
            {
                // Else we can only display something like ">20 matching rooms"
                self->_searchResultsCount = self->rooms.count;
                self->_searchResultsCountIsLimited = publicRoomsResponse.nextBatch ? YES : NO;
            }

            // Detect pagination end
            if (!publicRoomsResponse.nextBatch)
            {
                self->_hasReachedPaginationEnd = YES;
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

            if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled)
            {
                // Do not take into account error coming from a cancellation
                return;
            }

            self->publicRoomsRequest = nil;

            MXLogDebug(@"[PublicRoomsDirectoryDataSource] Failed to fecth public rooms.");

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

- (NSArray<MXPublicRoom*>*)filterPublicRooms:(NSArray<MXPublicRoom*>*)publicRooms
{
    NSMutableArray *filteredRooms = [NSMutableArray new];

    for (MXPublicRoom *publicRoom in publicRooms)
    {
        BOOL shouldAllow = YES;
        
        if (publicRoom.name != nil) {
            shouldAllow &= [self.forbiddenTermsRegex numberOfMatchesInString:publicRoom.name options:0 range:NSMakeRange(0, publicRoom.name.length)] == 0;
        }
        
        if (publicRoom.topic != nil) {
            shouldAllow &= [self.forbiddenTermsRegex numberOfMatchesInString:publicRoom.topic options:0 range:NSMakeRange(0, publicRoom.topic.length)] == 0;
        }
        
        if (shouldAllow) {
            [filteredRooms addObject:publicRoom];
        }
    }
    
    return filteredRooms;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Display a default cell when no rooms is available.
    return rooms.count ? rooms.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Sanity check
    if (indexPath.row < rooms.count)
    {
        PublicRoomTableViewCell *publicRoomCell = [tableView dequeueReusableCellWithIdentifier:[PublicRoomTableViewCell defaultReuseIdentifier]];
        if (!publicRoomCell)
        {
            publicRoomCell = [[PublicRoomTableViewCell alloc] init];
        }
        
        [publicRoomCell render:rooms[indexPath.row] withMatrixSession:self.mxSession];
        return publicRoomCell;
    }
    else
    {
        MXKTableViewCell *tableViewCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
        if (!tableViewCell)
        {
            tableViewCell = [[MXKTableViewCell alloc] init];
            tableViewCell.textLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
            tableViewCell.textLabel.font = [UIFont systemFontOfSize:15.0];
            tableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
        }

        if (state == MXKDataSourceStateReady)
        {
            if (_searchPattern.length)
            {
                tableViewCell.textLabel.text = [VectorL10n searchNoResult];
            }
            else
            {
                tableViewCell.textLabel.text = [VectorL10n roomDirectoryNoPublicRoom];
            }
        }
        else
        {
            if (_searchPattern.length)
            {
                tableViewCell.textLabel.text = [VectorL10n searchInProgress];
            }
            else
            {
                // Show nothing in other cases
                tableViewCell.textLabel.text = @"";
            }
        }
        
        return tableViewCell;
    }
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    PublicRoomsDirectoryDataSource *source = [[[self class] allocWithZone:zone] initWithMatrixSession:self.mxSession];
    
    source.homeserver = [self.homeserver copyWithZone:zone];
    source.includeAllNetworks = self.includeAllNetworks;
    if (self.thirdpartyProtocolInstance)
    {
        source.thirdpartyProtocolInstance = [MXThirdPartyProtocolInstance modelFromJSON:self.thirdpartyProtocolInstance.JSONDictionary];
    }
    source.paginationLimit = self.paginationLimit;
    source.searchPattern = [self.searchPattern copyWithZone:zone];
    source->rooms = [rooms mutableCopyWithZone:zone];
    source->nextBatch = [nextBatch copyWithZone:zone];
    
    return source;
}

@end
