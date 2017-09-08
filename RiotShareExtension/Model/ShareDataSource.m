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
#import "RoomTableViewCell.h"
#import "MXRoom+Riot.h"

@interface ShareDataSource ()

@property (nonatomic, readwrite) ShareDataSourceMode dataSourceMode;

@property NSArray <MXRoom *> *rooms;
@property NSMutableArray <MXRoom *> *visibleRooms;

@end

@implementation ShareDataSource

- (instancetype)initWithMode:(ShareDataSourceMode)dataSourceMode
{
    self = [super init];
    if (self)
    {
        self.dataSourceMode = dataSourceMode;
        _rooms = [NSMutableArray array];
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
            __strong MXSession *session = weakSession;
            [self getRoomsFromStore:fileStore session:session];
        }
    } failure:^(NSError *error) {
        NSLog(@"[ShareExtensionManager failed to set store]");
    }];
}
     
- (void)getRoomsFromStore:(MXFileStore *)fileStore session:(MXSession *)session
{
    NSMutableArray *rooms = [NSMutableArray array];
    [fileStore asyncRoomsSummaries:^(NSArray<MXRoomSummary *> * _Nonnull roomsSummaries) {
        for (MXRoomSummary *roomSummary in roomsSummaries)
        {
            [fileStore asyncAccountDataOfRoom:roomSummary.roomId success:^(MXRoomAccountData * _Nonnull accountData) {
                [fileStore asyncStateEventsOfRoom:roomSummary.roomId success:^(NSArray<MXEvent *> * _Nonnull roomStateEvents) {
                    
                    MXRoom *room = [[MXRoom alloc] initWithRoomId:roomSummary.roomId andMatrixSession:session andStateEvents:roomStateEvents andAccountData:accountData];
                    
                    if ((self.dataSourceMode == DataSourceModeRooms) ^ roomSummary.isDirect)
                    {
                        [rooms addObject:room];
                    }
                    
                    if ([roomsSummaries indexOfObject:roomSummary] == roomsSummaries.count - 1)
                    {
                        self.rooms = rooms;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate dataSource:self didCellChange:nil];
                        });
                    }
                    
                } failure:^(NSError * _Nonnull error) {
                    NSLog(@"[ShareExtensionManager failed to get state events]");
                }];
            } failure:^(NSError * _Nonnull error) {
                NSLog(@"[ShareExtensionManager failed to get account data]");
            }];
            
        }
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"[ShareExtensionManager failed to get room summaries]");
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
    if (self.visibleRooms)
    {
        return self.visibleRooms[indexPath.row];
    }
    return self.rooms[indexPath.row];
}

- (void)searchWithPatterns:(NSArray *)patternsList
{
    if (self.visibleRooms)
    {
        [self.visibleRooms removeAllObjects];
    }
    else
    {
        self.visibleRooms = [NSMutableArray arrayWithCapacity:self.rooms.count];
    }
    if (patternsList.count)
    {
        for (MXRoom *room in self.rooms)
        {
            for (NSString* pattern in patternsList)
            {
                if (room.riotDisplayname && [room.riotDisplayname rangeOfString:pattern options:NSCaseInsensitiveSearch].location != NSNotFound)
                {
                    [self.visibleRooms addObject:room];
                    break;
                }
            }
        }
    }
    else
    {
        self.visibleRooms = nil;
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
    if (self.visibleRooms)
    {
        return self.visibleRooms.count;
    }
    return self.rooms.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RoomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[RoomTableViewCell defaultReuseIdentifier]];
    
    MXRoom *room = [self getRoomAtIndexPath:indexPath];
    
    [cell render:room];
    
    return cell;
}


@end
