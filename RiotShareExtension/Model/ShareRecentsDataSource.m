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

#import "ShareRecentsDataSource.h"
#import "RoomTableViewCell.h"
#import "RecentCellData.h"

@interface ShareRecentsDataSource ()

@property (nonatomic, readwrite) ShareRecentsDataSourceMode dataSourceMode;

@property NSMutableArray *recentRooms;
@property NSMutableArray *recentPeople;

@end

@implementation ShareRecentsDataSource

- (instancetype)initWithMatrixSession:(MXSession *)mxSession dataSourceMode:(ShareRecentsDataSourceMode)dataSourceMode
{
    self = [super initWithMatrixSession:mxSession];
    if (self)
    {
        self.dataSourceMode = dataSourceMode;
        _recentRooms = [NSMutableArray array];
        _recentPeople = [NSMutableArray array];
    }
    return self;
}


#pragma mark - Private

- (void)updateArrays
{
    [self.recentPeople removeAllObjects];
    [self.recentRooms removeAllObjects];
    
    MXKSessionRecentsDataSource *recentsDataSource = displayedRecentsDataSourceArray.firstObject;
    NSInteger count = recentsDataSource.numberOfCells;
    
    for (int index = 0; index < count; index++)
    {
        id<MXKRecentCellDataStoring> cellData = [recentsDataSource cellDataAtIndex:index];
        MXRoom* room = cellData.roomSummary.room;
        
        if (self.dataSourceMode == RecentsDataSourceModePeople)
        {
            if (room.isDirect && room.state.membership == MXMembershipJoin)
            {
                [self.recentPeople addObject:cellData];
            }
        }
        else if (self.dataSourceMode == RecentsDataSourceModeRooms)
        {
            if (!room.isDirect && room.state.membership == MXMembershipJoin)
            {
                [self.recentRooms addObject:cellData];
            }
        }
    }
}

#pragma mark - MXKRecentsDataSource

- (Class)cellDataClassForCellIdentifier:(NSString *)identifier
{
    return RecentCellData.class;
}

- (id<MXKRecentCellDataStoring>)cellDataAtIndexPath:(NSIndexPath *)indexPath
{
    id<MXKRecentCellDataStoring> cellData = nil;
    
    if (self.dataSourceMode == RecentsDataSourceModePeople)
    {
        cellData = self.recentPeople[indexPath.row];
    }
    else
    {
        cellData = self.recentRooms[indexPath.row];
    }
    
    return cellData;
}

- (void)dataSource:(MXKDataSource*)dataSource didCellChange:(id)changes
{
    [super dataSource:dataSource didCellChange:changes];
    
    [self updateArrays];
    [self.delegate dataSource:self didCellChange:changes];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.dataSourceMode == RecentsDataSourceModePeople)
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
    
    MXRoom *room = [self cellDataAtIndexPath:indexPath].roomSummary.room;
    
    [cell render:room];
    
    if (!room.summary.displayname.length && !cell.titleLabel.text.length)
    {
        cell.titleLabel.text = NSLocalizedStringFromTable(@"room_displayname_no_title", @"Vector", nil);
    }
    
    return cell;
}


@end
