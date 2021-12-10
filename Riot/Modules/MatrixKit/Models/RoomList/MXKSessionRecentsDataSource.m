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

#import "MXKSessionRecentsDataSource.h"

@import MatrixSDK;

#import "MXKRoomDataSourceManager.h"

#import "MXKSwiftHeader.h"

#pragma mark - Constant definitions
NSString *const kMXKRecentCellIdentifier = @"kMXKRecentCellIdentifier";
static NSTimeInterval const roomSummaryChangeThrottlerDelay = .5;


@interface MXKSessionRecentsDataSource ()
{
    MXKRoomDataSourceManager *roomDataSourceManager;
    
    /**
     Internal array used to regulate change notifications.
     Cell data changes are stored instantly in this array.
     These changes are reported to the delegate only if no server sync is in progress.
     */
    NSMutableArray *internalCellDataArray;

    /**
     Store the current search patterns list.
     */
    NSArray* searchPatternsList;
    
    /**
     Do not react on every summary change
     */
    MXThrottler *roomSummaryChangeThrottler;
    
    /**
     Last received suggested rooms per space ID
     */
    NSMutableDictionary<NSString*, NSArray<MXSpaceChildInfo *> *> *lastSuggestedRooms;
    
    /**
     Event listener of the current space used to update the UI if an event occurs.
     */
    id spaceEventsListener;
    
    /**
     Observer used to reload data when the space service is initialised
     */
    id spaceServiceDidInitialiseObserver;
}

/**
 Additional suggestedRooms related to the current selected Space
 */
@property (nonatomic, strong) NSArray<MXSpaceChildInfo *> *suggestedRooms;

@end

@implementation MXKSessionRecentsDataSource

- (instancetype)initWithMatrixSession:(MXSession *)matrixSession
{
    self = [super initWithMatrixSession:matrixSession];
    if (self)
    {
        roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:self.mxSession];
        
        internalCellDataArray = [NSMutableArray array];
        filteredCellDataArray = nil;
        
        lastSuggestedRooms = [NSMutableDictionary new];
        
        // Set default data and view classes
        [self registerCellDataClass:MXKRecentCellData.class forCellIdentifier:kMXKRecentCellIdentifier];
        
        roomSummaryChangeThrottler = [[MXThrottler alloc] initWithMinimumDelay:roomSummaryChangeThrottlerDelay];
        
        [[MXKAppSettings standardAppSettings] addObserver:self forKeyPath:@"showAllRoomsInHomeSpace" options:0 context:nil];
    }
    return self;
}

- (void)destroy
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXRoomSummaryDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKRoomDataSourceSyncStatusChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionNewRoomNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionDidLeaveRoomNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionDirectRoomsDidChangeNotification object:nil];
    
    if (spaceServiceDidInitialiseObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:spaceServiceDidInitialiseObserver];
    }
    
    [roomSummaryChangeThrottler cancelAll];
    roomSummaryChangeThrottler = nil;
    
    cellDataArray = nil;
    internalCellDataArray = nil;
    filteredCellDataArray = nil;
    lastSuggestedRooms = nil;
    
    searchPatternsList = nil;
    
    [[MXKAppSettings standardAppSettings] removeObserver:self forKeyPath:@"showAllRoomsInHomeSpace" context:nil];

    [super destroy];
}

- (void)didMXSessionStateChange
{
    if (MXSessionStateStoreDataReady <= self.mxSession.state)
    {
        // Check whether some data have been already load
        if (0 == internalCellDataArray.count)
        {
            [self loadData];
        }
        else if (!roomDataSourceManager.isServerSyncInProgress)
        {
            // Sort cell data and notify the delegate
            [self sortCellDataAndNotifyChanges];
        }
    }
}

- (void)setCurrentSpace:(MXSpace *)currentSpace
{
    if (_currentSpace == currentSpace)
    {
        return;
    }
    
    if (_currentSpace && spaceEventsListener)
    {
        [_currentSpace.room removeListener:spaceEventsListener];
    }
    
    _currentSpace = currentSpace;
    
    self.suggestedRooms = _currentSpace ? lastSuggestedRooms[_currentSpace.spaceId] : nil;
    [self updateSuggestedRooms];
    
    MXWeakify(self);
    spaceEventsListener = [self.currentSpace.room listenToEvents:^(MXEvent *event, MXTimelineDirection direction, MXRoomState *roomState) {
        MXStrongifyAndReturnIfNil(self);
        [self updateSuggestedRooms];
    }];
}

-(void)setSuggestedRooms:(NSArray<MXSpaceChildInfo *> *)suggestedRooms
{
    _suggestedRooms = suggestedRooms;
    [self loadData];
}

-(void)updateSuggestedRooms
{
    if (self.currentSpace)
    {
        NSString *currentSpaceId = self.currentSpace.spaceId;
        MXWeakify(self);
        [self.mxSession.spaceService getSpaceChildrenForSpaceWithId:currentSpaceId suggestedOnly:YES limit:5 maxDepth:1 paginationToken:nil success:^(MXSpaceChildrenSummary * _Nonnull childrenSummary) {
            MXLogDebug(@"[MXKSessionRecentsDataSource] getSpaceChildrenForSpaceWithId %@: %ld found", self.currentSpace.spaceId, childrenSummary.childInfos.count);
            MXStrongifyAndReturnIfNil(self);
            self->lastSuggestedRooms[currentSpaceId] = childrenSummary.childInfos;
            if ([self.currentSpace.spaceId isEqual:currentSpaceId]) {
                self.suggestedRooms = childrenSummary.childInfos;
            }
        } failure:^(NSError * _Nonnull error) {
            MXLogError(@"[MXKSessionRecentsDataSource] getSpaceChildrenForSpaceWithId failed with error: %@", error);
        }];
    }
}

#pragma mark -

- (NSInteger)numberOfCells
{
    if (filteredCellDataArray)
    {
        return filteredCellDataArray.count;
    }
    return cellDataArray.count;
}

- (BOOL)hasUnread
{
    // Check all current cells
    // Use numberOfRowsInSection methods so that we take benefit of the filtering
    for (NSUInteger i = 0; i < self.numberOfCells; i++)
    {
        id<MXKRecentCellDataStoring> cellData = [self cellDataAtIndex:i];
        if (cellData.hasUnread)
        {
            return YES;
        }
    }
    return NO;
}

- (void)searchWithPatterns:(NSArray*)patternsList
{
    if (patternsList.count)
    {
        searchPatternsList = patternsList;
        
        if (filteredCellDataArray)
        {
            [filteredCellDataArray removeAllObjects];
        }
        else
        {
            filteredCellDataArray = [NSMutableArray arrayWithCapacity:cellDataArray.count];
        }
        
        for (id<MXKRecentCellDataStoring> cellData in cellDataArray)
        {
            for (NSString* pattern in patternsList)
            {
                if (cellData.roomDisplayname && [cellData.roomDisplayname rangeOfString:pattern options:NSCaseInsensitiveSearch].location != NSNotFound)
                {
                    [filteredCellDataArray addObject:cellData];
                    break;
                }
            }
        }
    }
    else
    {
        filteredCellDataArray = nil;
        searchPatternsList = nil;
    }
    
    [self.delegate dataSource:self didCellChange:nil];
}

- (id<MXKRecentCellDataStoring>)cellDataAtIndex:(NSInteger)index
{
    if (filteredCellDataArray)
    {
        if (index < filteredCellDataArray.count)
        {
            return filteredCellDataArray[index];
        }
    }
    else if (index < cellDataArray.count)
    {
        return cellDataArray[index];
    }
    
    return nil;
}

- (CGFloat)cellHeightAtIndex:(NSInteger)index
{
    if (self.delegate)
    {
        id<MXKRecentCellDataStoring> cellData = [self cellDataAtIndex:index];
        
        Class<MXKCellRendering> class = [self.delegate cellViewClassForCellData:cellData];
        return [class heightForCellData:cellData withMaximumWidth:0];
    }
    
    return 0;
}

#pragma mark - Events processing

/**
 Filtering in this method won't have any effect anymore. This class is not maintained.
 */
- (void)loadData
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXRoomSummaryDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKRoomDataSourceSyncStatusChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionNewRoomNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionDidLeaveRoomNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionDirectRoomsDidChangeNotification object:nil];
    
    if (!self.mxSession.spaceService.isInitialised && !spaceServiceDidInitialiseObserver) {
        MXWeakify(self);
        spaceServiceDidInitialiseObserver = [[NSNotificationCenter defaultCenter] addObserverForName:MXSpaceService.didInitialise object:self.mxSession.spaceService queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            MXStrongifyAndReturnIfNil(self);
            [self loadData];
        }];
    }
    
    // Reset the table
    [internalCellDataArray removeAllObjects];
    
    // Retrieve the MXKCellData class to manage the data
    Class class = [self cellDataClassForCellIdentifier:kMXKRecentCellIdentifier];
    NSAssert([class conformsToProtocol:@protocol(MXKRecentCellDataStoring)], @"MXKSessionRecentsDataSource only manages MXKCellData that conforms to MXKRecentCellDataStoring protocol");

    NSDate *startDate = [NSDate date];
    
    for (MXRoomSummary *roomSummary in self.mxSession.roomsSummaries)
    {
        // Filter out private rooms with conference users
        if (!roomSummary.isConferenceUserRoom // @TODO Abstract this condition with roomSummary.hiddenFromUser
            && !roomSummary.hiddenFromUser)
        {
            id<MXKRecentCellDataStoring> cellData = [[class alloc] initWithRoomSummary:roomSummary dataSource:self];
            if (cellData)
            {
                [internalCellDataArray addObject:cellData];
            }
        }
    }
    
    for (MXSpaceChildInfo *childInfo in _suggestedRooms)
    {
        id<MXRoomSummaryProtocol> summary = [[MXRoomSummary alloc] initWithSpaceChildInfo:childInfo];
        id<MXKRecentCellDataStoring> cellData = [[class alloc] initWithRoomSummary:summary
                                                                        dataSource:self];
        if (cellData)
        {
            [internalCellDataArray addObject:cellData];
        }
    }

    MXLogDebug(@"[MXKSessionRecentsDataSource] Loaded %tu recents in %.3fms", self.mxSession.rooms.count, [[NSDate date] timeIntervalSinceDate:startDate] * 1000);

    // Make sure all rooms have a last message
    [self.mxSession fixRoomsSummariesLastMessage];

    // Report loaded array except if sync is in progress
    if (!roomDataSourceManager.isServerSyncInProgress)
    {
        [self sortCellDataAndNotifyChanges];
    }
    
    // Listen to MXSession rooms count changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didMXSessionHaveNewRoom:) name:kMXSessionNewRoomNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didMXSessionDidLeaveRoom:) name:kMXSessionDidLeaveRoomNotification object:nil];
    
    // Listen to the direct rooms list
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDirectRoomsChange:) name:kMXSessionDirectRoomsDidChangeNotification object:nil];
    
    // Listen to MXRoomSummary
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRoomSummaryChanged:) name:kMXRoomSummaryDidChangeNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didMXSessionStateChange) name:kMXKRoomDataSourceSyncStatusChanged object:nil];
}

- (void)didDirectRoomsChange:(NSNotification *)notif
{
    // Inform the delegate about the update
    [self.delegate dataSource:self didCellChange:nil];
}

- (void)didRoomSummaryChanged:(NSNotification *)notif
{    
    [roomSummaryChangeThrottler throttle:^{
        [self didRoomSummaryChanged2:notif];
    }];
}

- (void)didRoomSummaryChanged2:(NSNotification *)notif
{
    MXRoomSummary *roomSummary = notif.object;
    if (roomSummary.mxSession == self.mxSession && internalCellDataArray.count)
    {
        // Find the index of the related cell data
        NSInteger index = NSNotFound;
        for (index = 0; index < internalCellDataArray.count; index++)
        {
            id<MXKRecentCellDataStoring> theRoomData = [internalCellDataArray objectAtIndex:index];
            if (theRoomData.roomSummary == roomSummary)
            {
                break;
            }
        }
        
        if (index < internalCellDataArray.count)
        {
            if (roomSummary.hiddenFromUser)
            {
                [internalCellDataArray removeObjectAtIndex:index];
            }
            else
            {
                // Create a new instance to not modify the content of 'cellDataArray' (the copy is not a deep copy).
                Class class = [self cellDataClassForCellIdentifier:kMXKRecentCellIdentifier];
                id<MXKRecentCellDataStoring> cellData = [[class alloc] initWithRoomSummary:roomSummary dataSource:self];
                if (cellData)
                {
                    [internalCellDataArray replaceObjectAtIndex:index withObject:cellData];
                }
            }
            
            // Report change except if sync is in progress
            if (!roomDataSourceManager.isServerSyncInProgress)
            {
                [self sortCellDataAndNotifyChanges];
            }
        }
        else
        {
            MXLogDebug(@"[MXKSessionRecentsDataSource] didRoomLastMessageChanged: Cannot find the changed room summary for %@ (%@). It is probably not managed by this recents data source", roomSummary.roomId, roomSummary);
        }
    }
    else
    {
        // Inform the delegate that all the room summaries have been updated.
        [self.delegate dataSource:self didCellChange:nil];
    }
}

- (void)didMXSessionHaveNewRoom:(NSNotification *)notif
{
    MXSession *mxSession = notif.object;
    if (mxSession == self.mxSession)
    {
        NSString *roomId = notif.userInfo[kMXSessionNotificationRoomIdKey];
        
        // Add the room if there is not yet a cell for it
        id<MXKRecentCellDataStoring> roomData = [self cellDataWithRoomId:roomId];
        if (nil == roomData)
        {
            MXLogDebug(@"MXKSessionRecentsDataSource] Add newly joined room: %@", roomId);
            
            // Retrieve the MXKCellData class to manage the data
            Class class = [self cellDataClassForCellIdentifier:kMXKRecentCellIdentifier];

            MXRoomSummary *roomSummary = [mxSession roomSummaryWithRoomId:roomId];
            id<MXKRecentCellDataStoring> cellData = [[class alloc] initWithRoomSummary:roomSummary dataSource:self];
            if (cellData)
            {
                [internalCellDataArray addObject:cellData];
                
                // Report change except if sync is in progress
                if (!roomDataSourceManager.isServerSyncInProgress)
                {
                    [self sortCellDataAndNotifyChanges];
                }
            }
        }
    }
}

- (void)didMXSessionDidLeaveRoom:(NSNotification *)notif
{
    MXSession *mxSession = notif.object;
    if (mxSession == self.mxSession)
    {
        NSString *roomId = notif.userInfo[kMXSessionNotificationRoomIdKey];
        id<MXKRecentCellDataStoring> roomData = [self cellDataWithRoomId:roomId];
        
        if (roomData)
        {
            MXLogDebug(@"MXKSessionRecentsDataSource] Remove left room: %@", roomId);
            
            [internalCellDataArray removeObject:roomData];
            
            // Report change except if sync is in progress
            if (!roomDataSourceManager.isServerSyncInProgress)
            {
                [self sortCellDataAndNotifyChanges];
            }
        }
    }
}

// Order cells
- (void)sortCellDataAndNotifyChanges
{
    // Order them by origin_server_ts
    [internalCellDataArray sortUsingComparator:^NSComparisonResult(id<MXKRecentCellDataStoring> cellData1, id<MXKRecentCellDataStoring> cellData2)
    {
        return [cellData1.roomSummary.lastMessage compareOriginServerTs:cellData2.roomSummary.lastMessage];
    }];
    
    // Snapshot the cell data array
    cellDataArray = [internalCellDataArray copy];
    
    // Update search result if any
    if (searchPatternsList)
    {
        [self searchWithPatterns:searchPatternsList];
    }
    
    // Update here data source state
    if (state != MXKDataSourceStateReady)
    {
        state = MXKDataSourceStateReady;
        if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:didStateChange:)])
        {
            [self.delegate dataSource:self didStateChange:state];
        }
    }
    
    // And inform the delegate about the update
    [self.delegate dataSource:self didCellChange:nil];
}

// Find the cell data that stores information about the given room id
- (id<MXKRecentCellDataStoring>)cellDataWithRoomId:(NSString*)roomId
{
    id<MXKRecentCellDataStoring> theRoomData;
    
    NSMutableArray *dataArray = internalCellDataArray;
    if (!roomDataSourceManager.isServerSyncInProgress)
    {
        dataArray = cellDataArray;
    }
    
    for (id<MXKRecentCellDataStoring> roomData in dataArray)
    {
        if ([roomData.roomSummary.roomId isEqualToString:roomId])
        {
            theRoomData = roomData;
            break;
        }
    }
    return theRoomData;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == [MXKAppSettings standardAppSettings] && [keyPath isEqualToString:@"showAllRoomsInHomeSpace"])
    {
        if (self.currentSpace == nil)
        {
            [self loadData];
        }
    }
}

@end
