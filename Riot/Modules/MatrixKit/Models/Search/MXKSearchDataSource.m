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

#import "MXKSearchDataSource.h"

#import "MXKSearchCellData.h"

#pragma mark - Constant definitions
NSString *const kMXKSearchCellDataIdentifier = @"kMXKSearchCellDataIdentifier";


@interface MXKSearchDataSource ()
{
    /**
     The current search request.
     */
    MXHTTPOperation *searchRequest;

    /**
     Token that can be used to get the next batch of results in the group, if exists.
     */
    NSString *nextBatch;
}

@end

@implementation MXKSearchDataSource 

- (instancetype)initWithMatrixSession:(MXSession *)mxSession
{
    self = [super initWithMatrixSession:mxSession];
    if (self)
    {
        // Set default data and view classes
        // Cell data
        [self registerCellDataClass:MXKSearchCellData.class forCellIdentifier:kMXKSearchCellDataIdentifier];

        // Set default MXEvent -> NSString formatter
        _eventFormatter = [[MXKEventFormatter alloc] initWithMatrixSession:mxSession];
        
        _roomEventFilter = [[MXRoomEventFilter alloc] init];

        cellDataArray = [NSMutableArray array];
    }
    return self;
}

- (void)destroy
{
    cellDataArray = nil;
    _eventFormatter = nil;
    
    _roomEventFilter = nil;
    
    [super destroy];
}

- (void)searchMessages:(NSString*)textPattern force:(BOOL)force
{
    if (force || ![_searchText isEqualToString:textPattern])
    {
        // Reset data before making the new search
        if (searchRequest)
        {
            [searchRequest cancel];
            searchRequest = nil;
        }
        
        _searchText = textPattern;
        _serverCount = 0;
        _canPaginate = NO;
        nextBatch = nil;
        
        self.state = MXKDataSourceStatePreparing;
        [cellDataArray removeAllObjects];
        
        if (textPattern.length)
        {
            MXLogDebug(@"[MXKSearchDataSource] searchMessages: %@", textPattern);
            [self doSearch];
        }
        else
        {
            // Refresh table display.
            self.state = MXKDataSourceStateReady;
            [self.delegate dataSource:self didCellChange:nil];
        }
    }
}

- (void)paginateBack
{
    MXLogDebug(@"[MXKSearchDataSource] paginateBack");

    self.state = MXKDataSourceStatePreparing;
    [self doSearch];
}

- (MXKCellData*)cellDataAtIndex:(NSInteger)index
{
    MXKCellData *cellData;
    if (index < cellDataArray.count)
    {
        cellData = cellDataArray[index];
    }

    return cellData;
}

- (void)convertHomeserverResultsIntoCells:(MXSearchRoomEventResults*)roomEventResults onComplete:(dispatch_block_t)onComplete
{
    // Retrieve the MXKCellData class to manage the data
    // Note: MXKSearchDataSource only manages MXKCellData that conforms to MXKSearchCellDataStoring protocol
    // see `[registerCellDataClass:forCellIdentifier:]`
    Class class = [self cellDataClassForCellIdentifier:kMXKSearchCellDataIdentifier];

    dispatch_group_t group = dispatch_group_create();

    for (MXSearchResult *result in roomEventResults.results)
    {
        dispatch_group_enter(group);
        [class cellDataWithSearchResult:result andSearchDataSource:self onComplete:^(__autoreleasing id<MXKSearchCellDataStoring> cellData) {
            dispatch_group_leave(group);

            if (cellData)
            {
                ((id<MXKSearchCellDataStoring>)cellData).shouldShowRoomDisplayName = self.shouldShowRoomDisplayName;

                // Use profile information as data to display
                MXSearchUserProfile *userProfile = result.context.profileInfo[result.result.sender];
                cellData.senderDisplayName = userProfile.displayName;

                [self->cellDataArray insertObject:cellData atIndex:0];
            }
        }];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        onComplete();
    });
}

#pragma mark - Private methods

// Update the MXKDataSource and notify the delegate
- (void)setState:(MXKDataSourceState)newState
{
    state = newState;

    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(dataSource:didStateChange:)])
        {
            [self.delegate dataSource:self didStateChange:state];
        }
    }
}

- (void)doSearch
{
    // Handle one request at a time
    if (searchRequest)
    {
        return;
    }

    NSDate *startDate = [NSDate date];

    MXWeakify(self);
    searchRequest = [self.mxSession.matrixRestClient searchMessagesWithText:_searchText roomEventFilter:_roomEventFilter beforeLimit:0 afterLimit:0 nextBatch:nextBatch success:^(MXSearchRoomEventResults *roomEventResults) {
        MXStrongifyAndReturnIfNil(self);

        MXLogDebug(@"[MXKSearchDataSource] searchMessages: %@ (%d). Done in %.3fms - Got %tu / %tu messages", self.searchText, self.roomEventFilter.containsURL, [[NSDate date] timeIntervalSinceDate:startDate] * 1000, roomEventResults.results.count, roomEventResults.count);

        self->searchRequest = nil;
        self->_serverCount = roomEventResults.count;
        self->nextBatch = roomEventResults.nextBatch;
        self->_canPaginate = (nil != self->nextBatch);

        // Process HS response to cells data
        MXWeakify(self);
        [self convertHomeserverResultsIntoCells:roomEventResults onComplete:^{
            MXStrongifyAndReturnIfNil(self);

            self.state = MXKDataSourceStateReady;

            // Provide changes information to the delegate
            NSIndexSet *insertedIndexes;
            if (roomEventResults.results.count)
            {
                insertedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, roomEventResults.results.count)];
            }

            [self.delegate dataSource:self didCellChange:insertedIndexes];
        }];

    } failure:^(NSError *error) {
        MXStrongifyAndReturnIfNil(self);

        self->searchRequest = nil;
        self.state = MXKDataSourceStateFailed;
    }];
}

#pragma mark - Override MXKDataSource

- (void)registerCellDataClass:(Class)cellDataClass forCellIdentifier:(NSString *)identifier
{
    if ([identifier isEqualToString:kMXKSearchCellDataIdentifier])
    {
        // Sanity check
        NSAssert([cellDataClass conformsToProtocol:@protocol(MXKSearchCellDataStoring)], @"MXKSearchDataSource only manages MXKCellData that conforms to MXKSearchCellDataStoring protocol");
    }
    
    [super registerCellDataClass:cellDataClass forCellIdentifier:identifier];
}

- (void)cancelAllRequests
{
    if (searchRequest)
    {
        [searchRequest cancel];
        searchRequest = nil;
    }

    [super cancelAllRequests];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return cellDataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MXKCellData* cellData = [self cellDataAtIndex:indexPath.row];

    NSString *cellIdentifier = [self.delegate cellReuseIdentifierForCellData:cellData];
    if (cellIdentifier)
    {
        UITableViewCell<MXKCellRendering> *cell  = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

        // Make the bubble display the data
        [cell render:cellData];

        // Disable any interactions defined in the cell
        // because we want [tableView didSelectRowAtIndexPath:] to be called
        cell.contentView.userInteractionEnabled = NO;

        // Force background color change on selection
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;

        return cell;
    }

    // Return a fake cell to prevent app from crashing.
    return [[UITableViewCell alloc] init];
}

@end
