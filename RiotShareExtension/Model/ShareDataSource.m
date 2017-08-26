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

@interface ShareDataSource ()

@property (nonatomic, readwrite) ShareDataSourceMode dataSourceMode;

@property NSMutableArray *recentRooms;
@property NSMutableArray *recentPeople;

@end

@implementation ShareDataSource

- (instancetype)initWithMode:(ShareDataSourceMode)dataSourceMode
{
    if (self)
    {
        self.dataSourceMode = dataSourceMode;
        _recentRooms = [NSMutableArray array];
        _recentPeople = [NSMutableArray array];
        [self updateRooms];
    }
    return self;
}


#pragma mark - Private

- (void)updateRooms
{
    [self.recentRooms removeAllObjects];
    [self.recentPeople removeAllObjects];
    
    MXFileStore *fileStore = [[MXFileStore alloc] initWithCredentials:[ShareExtensionManager sharedManager].account.mxCredentials];
    
    [fileStore asyncRoomsSummaries:^(NSArray<MXRoomSummary *> * _Nonnull roomsSummaries) {
        for (MXRoomSummary *roomSummary in roomsSummaries)
        {
            if (self.dataSourceMode == DataSourceModePeople)
            {
                if (roomSummary.isDirect)
                {
                    [self.recentPeople addObject:roomSummary];
                }
            }
            else
            {
                if (!roomSummary.isDirect)
                {
                    [self.recentRooms addObject:roomSummary];
                }
            }
            [self.delegate dataSource:self didCellChange:nil];
        }
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"[ShareExtensionManager failed to get room summaries]");
    }];
}


- (MXRoomSummary *)getRoomSummaryAtIndexPath:(NSIndexPath *)indexPath
{
    MXRoomSummary *room = nil;
    
    if (self.dataSourceMode == DataSourceModePeople)
    {
        room = self.recentPeople[indexPath.row];
    }
    else
    {
        room = self.recentRooms[indexPath.row];
    }
    
    return room;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.dataSourceMode == DataSourceModePeople)
    {
        return self.recentPeople.count;
    }
    else
    {
        return self.recentRooms.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RoomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[RoomTableViewCell defaultReuseIdentifier]];
    
    MXRoomSummary *roomSummary = [self getRoomSummaryAtIndexPath:indexPath];
    
    [cell renderWithSummary:roomSummary restClient:[ShareExtensionManager sharedManager].mxRestClient];
    
    if (!roomSummary.displayname.length && !cell.titleLabel.text.length)
    {
        cell.titleLabel.text = NSLocalizedStringFromTable(@"room_displayname_no_title", @"Vector", nil);
    }
    
    return cell;
}


@end
