/*
 Copyright 2017 Aram Sargsyan
 
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

#import "ShareDataSource.h"
#import "RecentRoomTableViewCell.h"

@interface ShareDataSource ()

@property (nonatomic, strong, readonly) MXFileStore *fileStore;
@property (nonatomic, strong, readonly) MXSession *session;

@property NSArray <MXKRecentCellData *> *recentCellDatas;
@property NSMutableArray <MXKRecentCellData *> *visibleRoomCellDatas;

@property (nonatomic, strong) NSMutableSet<NSString *> *internalSelectedRoomIdentifiers;

@end

@implementation ShareDataSource

- (instancetype)initWithFileStore:(MXFileStore *)fileStore
                          session:(MXSession *)session
{
    if (self = [super init])
    {
        _fileStore = fileStore;
        _session = session;
        
        _internalSelectedRoomIdentifiers = [NSMutableSet set];
        
        [self loadCellData];
    }
    return self;
}

- (void)destroy
{
    [super destroy];
    
    _recentCellDatas = nil;
    _visibleRoomCellDatas = nil;
}

- (NSSet<NSString *> *)selectedRoomIdentifiers
{
    return self.internalSelectedRoomIdentifiers.copy;
}

- (void)selectRoomWithIdentifier:(NSString *)roomIdentifier animated:(BOOL)animated
{
    [self.internalSelectedRoomIdentifiers addObject:roomIdentifier];
    
    [self.shareDelegate shareDataSourceDidChangeSelectedRoomIdentifiers:self];
}

- (void)deselectRoomWithIdentifier:(NSString *)roomIdentifier animated:(BOOL)animated
{
    [self.internalSelectedRoomIdentifiers removeObject:roomIdentifier];
    
    [self.shareDelegate shareDataSourceDidChangeSelectedRoomIdentifiers:self];
}

#pragma mark - Private
     
- (void)loadCellData
{
    [self.fileStore.roomSummaryStore fetchAllSummaries:^(NSArray<id<MXRoomSummaryProtocol>> *summaries) {
        
        NSMutableArray *cellData = [NSMutableArray array];
        
        for (id<MXRoomSummaryProtocol> summary in summaries)
        {
            if (!summary.hiddenFromUser && summary.roomType == MXRoomTypeRoom)
            {
                if ([summary respondsToSelector:@selector(setMatrixSession:)])
                {
                    [summary setMatrixSession:self.session];
                }
                
                MXKRecentCellData *recentCellData = [[MXKRecentCellData alloc] initWithRoomSummary:summary dataSource:nil];
                
                [cellData addObject:recentCellData];
            }
        }
        
        // Sort rooms according to their last messages (most recent first)
        NSComparator comparator = ^NSComparisonResult(MXKRecentCellData *recentCellData1, MXKRecentCellData *recentCellData2) {

            return [recentCellData1.roomSummary.lastMessage compareOriginServerTs:recentCellData2.roomSummary.lastMessage];
        };
        [cellData sortUsingComparator:comparator];
        
        self.recentCellDatas = cellData;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.delegate dataSource:self didCellChange:nil];
            
        });
        
    }];
}

#pragma mark - MXKRecentsDataSource

- (MXKRecentCellData *)cellDataAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.visibleRoomCellDatas)
    {
        return self.visibleRoomCellDatas[indexPath.row];
    }
    return self.recentCellDatas[indexPath.row];
}

- (void)searchWithPatterns:(NSArray *)patternsList
{
    if (self.visibleRoomCellDatas)
    {
        [self.visibleRoomCellDatas removeAllObjects];
    }
    else
    {
        self.visibleRoomCellDatas = [NSMutableArray arrayWithCapacity:self.recentCellDatas.count];
    }
    if (patternsList.count)
    {
        for (MXKRecentCellData *cellData in self.recentCellDatas)
        {
            for (NSString* pattern in patternsList)
            {
                if (cellData.roomSummary.displayname && [cellData.roomSummary.displayname rangeOfString:pattern options:NSCaseInsensitiveSearch].location != NSNotFound)
                {
                    [self.visibleRoomCellDatas addObject:cellData];
                    break;
                }
            }
        }
    }
    else
    {
        self.visibleRoomCellDatas = nil;
    }
    
    [self.delegate dataSource:self didCellChange:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.visibleRoomCellDatas)
    {
        return self.visibleRoomCellDatas.count;
    }
    return self.recentCellDatas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RecentRoomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[RecentRoomTableViewCell defaultReuseIdentifier]];
    
    MXKRecentCellData *data = [self cellDataAtIndexPath:indexPath];
    
    [cell render:data];
    
    [cell setCustomSelected:[self.selectedRoomIdentifiers containsObject:data.roomSummary.roomId] animated:NO];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}


@end
