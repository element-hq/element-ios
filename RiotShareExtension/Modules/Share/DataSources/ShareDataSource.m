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
#import "ShareExtensionManager.h"
#import "RecentRoomTableViewCell.h"

@interface ShareDataSource ()

@property (nonatomic, readwrite) ShareDataSourceMode dataSourceMode;

@property NSArray <MXKRecentCellData *> *recentCellDatas;
@property NSMutableArray <MXKRecentCellData *> *visibleRoomCellDatas;

@end

@implementation ShareDataSource

- (instancetype)initWithMode:(ShareDataSourceMode)dataSourceMode
{
    self = [super init];
    if (self)
    {
        self.dataSourceMode = dataSourceMode;
        
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

#pragma mark - Private
     
- (void)loadCellData
{
    [[ShareExtensionManager sharedManager].fileStore asyncRoomsSummaries:^(NSArray<MXRoomSummary *> * _Nonnull roomsSummaries) {
        
        NSMutableArray *cellData = [NSMutableArray array];
        
        // Add a fake matrix session to each room summary to provide it a REST client (used to handle correctly the room avatar).
        MXSession *session = [[MXSession alloc] initWithMatrixRestClient:[[MXRestClient alloc] initWithCredentials:[ShareExtensionManager sharedManager].userAccount.mxCredentials andOnUnrecognizedCertificateBlock:nil]];
        
        for (MXRoomSummary *roomSummary in roomsSummaries)
        {
            if ((self.dataSourceMode == DataSourceModeRooms) ^ roomSummary.isDirect)
            {
                [roomSummary setMatrixSession:session];
                
                MXKRecentCellData *recentCellData = [[MXKRecentCellData alloc] initWithRoomSummary:roomSummary andRecentListDataSource:nil];
                
                [cellData addObject:recentCellData];
            }
        }
        
        // Sort rooms according to their last messages (most recent first)
        NSComparator comparator = ^NSComparisonResult(MXKRecentCellData *recentCellData1, MXKRecentCellData *recentCellData2) {
            
            NSComparisonResult result = NSOrderedAscending;
            if (recentCellData2.roomSummary.lastMessageOriginServerTs > recentCellData1.roomSummary.lastMessageOriginServerTs)
            {
                result = NSOrderedDescending;
            }
            else if (recentCellData2.roomSummary.lastMessageOriginServerTs == recentCellData1.roomSummary.lastMessageOriginServerTs)
            {
                result = NSOrderedSame;
            }
            return result;
        };
        [cellData sortUsingComparator:comparator];
        
        self.recentCellDatas = cellData;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.delegate dataSource:self didCellChange:nil];
            
        });
        
    } failure:^(NSError * _Nonnull error) {
        
        NSLog(@"[ShareDataSource failed to get room summaries]");
        
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
    
    [cell render:[self cellDataAtIndexPath:indexPath]];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}


@end
