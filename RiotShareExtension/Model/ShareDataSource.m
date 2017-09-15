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
//#import "MXRoom+Riot.h"

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
        _recentCellDatas = [NSMutableArray array];
        [self updateRooms];
    }
    return self;
}


#pragma mark - Private

- (void)updateRooms
{
    MXFileStore *fileStore = [[MXFileStore alloc] initWithCredentials:[ShareExtensionManager sharedManager].userAccount.mxCredentials];
    MXSession *session = [[MXSession alloc] initWithMatrixRestClient:[[MXRestClient alloc] initWithCredentials:[ShareExtensionManager sharedManager].userAccount.mxCredentials andOnUnrecognizedCertificateBlock:nil]];
    
    __weak MXSession *weakSession = session;
    [session setStore:fileStore success:^{
        if (weakSession)
        {
            //__strong MXSession *session = weakSession;
            [self getCellDatasFromStore:fileStore];
        }
    } failure:^(NSError *error) {
        NSLog(@"[ShareDataSource failed to set store]");
    }];
}
     
- (void)getCellDatasFromStore:(MXFileStore *)fileStore
{
    NSMutableArray *cellDatas = [NSMutableArray array];
    [fileStore asyncRoomsSummaries:^(NSArray<MXRoomSummary *> * _Nonnull roomsSummaries) {
        for (MXRoomSummary *roomSummary in roomsSummaries)
        {
            MXKRecentCellData *recentCellData = [[MXKRecentCellData alloc] initWithRoomSummary:roomSummary andRecentListDataSource:nil];
            
            
            if ((self.dataSourceMode == DataSourceModeRooms) ^ roomSummary.isDirect)
            {
                [cellDatas addObject:recentCellData];
            }
            
            if ([roomsSummaries indexOfObject:roomSummary] == roomsSummaries.count - 1)
            {
                self.recentCellDatas = cellDatas;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate dataSource:self didCellChange:nil];
                });
            }
            
        }
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"[ShareDataSource failed to get room summaries]");
    }];
}

#pragma mark - MXKRecentsDataSource

- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate dataSource:dataSource didCellChange:nil];
    });
}

- (MXRoom *)getRoomAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"vori");
    /*if (self.visibleRoomCellDatas)
    {
        return self.visibleRoomCellDatas[indexPath.row];
    }
    return self.visibleRoomCellDatas[indexPath.row];*/
    return nil;
}

- (id<MXKRecentCellDataStoring>)cellDataAtIndexPath:(NSIndexPath *)indexPath {
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


@end
