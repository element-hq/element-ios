//
//  ShareRecentsDataSource.m
//  Riot
//
//  Created by Aram Sargsyan on 8/10/17.
//  Copyright © 2017 matrix.org. All rights reserved.
//

#import "ShareRecentsDataSource.h"
#import "RoomTableViewCell.h"

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
        _recentRooms = [NSMutableArray array];
        _recentPeople = [NSMutableArray array];
        self.dataSourceMode = dataSourceMode;
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
            if (room.isDirect)
            {
                [self.recentPeople addObject:cellData];
            }
        }
        else if (self.dataSourceMode == RecentsDataSourceModeRooms)
        {
            if (!room.isDirect)
            {
                [self.recentRooms addObject:cellData];
            }
        }
    }
}

#pragma mark - MXKRecentsDataSource

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
