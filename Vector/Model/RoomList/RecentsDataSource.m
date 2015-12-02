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

#import "RecentsDataSource.h"

#import "RecentTableViewCell.h"

#import "EventFormatter.h"

@interface RecentsDataSource()
{
    NSMutableArray* favoritesCells;
    NSMutableArray* conversationCells;
    NSMutableArray* lowPriorityCells;
    
    NSInteger favoritesPos;
    NSInteger conversationPos;
    NSInteger lowPriorityPos;
    NSInteger sectionsCount;
    
    NSMutableDictionary<NSString*, id> *roomTagsListenerByUserId;
}
@end

@implementation RecentsDataSource

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        // Reset default view classes
        [self registerCellViewClass:RecentTableViewCell.class forCellIdentifier:kMXKRecentCellIdentifier];
        
        // Replace event formatter
        self.eventFormatter = [[EventFormatter alloc] initWithMatrixSession:self.mxSession];
        
        favoritesCells = [[NSMutableArray alloc] init];
        conversationCells = [[NSMutableArray alloc] init];
        lowPriorityCells = [[NSMutableArray alloc] init];
        
        favoritesPos = 0;
        conversationPos = 1;
        lowPriorityPos = 2;
        sectionsCount = 3;
        
        roomTagsListenerByUserId = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)removeMatrixSession:(MXSession*)matrixSession
{
    [super removeMatrixSession:matrixSession];
    
    // sanity check
    if (matrixSession && matrixSession.myUser && matrixSession.myUser.userId)
    {
        id roomTagListener = [roomTagsListenerByUserId objectForKey:matrixSession.myUser.userId];
        
        if (roomTagListener)
        {
            [self.mxSession removeListener:roomTagListener];
            [roomTagsListenerByUserId removeObjectForKey:matrixSession.myUser.userId];
        }
    }
}

- (void)dataSource:(MXKDataSource*)dataSource didStateChange:(MXKDataSourceState)aState
{
    [super dataSource:dataSource didStateChange:aState];
    
    if ((aState == MXKDataSourceStateReady) && self.mxSession && self.mxSession.myUser && self.mxSession.myUser.userId)
    {
        // Register the room tags updates to refresh the favorites order
        id roomTagsListener = [self.mxSession listenToEventsOfTypes:@[kMXEventTypeStringRoomTag]
                                                            onEvent:^(MXEvent *event, MXEventDirection direction, id customObject) {
                                                                
                                                                // Consider only live event
                                                                if (direction == MXEventDirectionForwards)
                                                                {
                                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                                        
                                                                        [self refreshRoomsSections];
                                                                        
                                                                        // And inform the delegate about the update
                                                                        [self.delegate dataSource:self didCellChange:nil];
                                                                    });
                                                                }
                                                                
                                                            }];
        
        [roomTagsListenerByUserId setObject:roomTagsListener forKey:self.mxSession.myUser.userId];
    }
}

#pragma mark - UITableViewDataSource

/**
 Return the header height from the section.
 */
- (CGFloat)heightForHeaderInSection:(NSInteger)section
{
    if ((section == favoritesPos) || (section == conversationPos) || (section == lowPriorityPos))
    {
        return 44.0f;
    }
    
    return 0.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Check whether all data sources are ready before rendering recents
    if (self.state == MXKDataSourceStateReady)
    {
        // Only one section is handled by this data source.
        return sectionsCount;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count = 0;
    
    if (section == favoritesPos)
    {
        count = favoritesCells.count;
    }
    else if (section == conversationPos)
    {
        count = conversationCells.count;
    }
    else if (section == lowPriorityPos)
    {
        count = lowPriorityCells.count;
    }

    return count;
}

- (UIView *)viewForHeaderInSection:(NSInteger)section withFrame:(CGRect)frame
{
    // add multi accounts section management
    
    if ((section == favoritesPos) || (section == conversationPos) || (section == lowPriorityPos))
    {
        UILabel* label = [[UILabel alloc] initWithFrame:frame];
        
        NSString* text = @"";
        
        if (section == favoritesPos)
        {
            text = NSLocalizedStringFromTable(@"room_recents_favourites", @"Vector", nil);
        }
        else if (section == conversationPos)
        {
            text = NSLocalizedStringFromTable(@"room_recents_conversations", @"Vector", nil);
        }
        else if (section == lowPriorityPos)
        {
            text = NSLocalizedStringFromTable(@"room_recents_low_priority", @"Vector", nil);
        }
    
        label.text = [NSString stringWithFormat:@"   %@", text];
        label.backgroundColor = [UIColor lightGrayColor];
        
        return label;
    }
    
    return [super viewForHeaderInSection:section withFrame:frame];
}

- (id<MXKRecentCellDataStoring>)cellDataAtIndexPath:(NSIndexPath *)indexPath
{
    id<MXKRecentCellDataStoring> cellData = nil;
    
    if (indexPath.section == favoritesPos)
    {
        cellData = [favoritesCells objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == conversationPos)
    {
        cellData = [conversationCells objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == lowPriorityPos)
    {
        cellData = [lowPriorityCells objectAtIndex:indexPath.row];
    }
    
    return cellData;
}

- (CGFloat)cellHeightAtIndexPath:(NSIndexPath *)indexPath
{
    id<MXKRecentCellDataStoring> cellData = [self cellDataAtIndexPath:indexPath];
    
    if (cellData)
    {
        Class<MXKCellRendering> class = [self cellViewClassForCellIdentifier:kMXKRecentCellIdentifier];
        return [class heightForCellData:cellData withMaximumWidth:0];
    }

    return 0;
}

#pragma mark - MXKDataSourceDelegate

- (void)refreshRoomsSections
{
    // displayedRecentsDataSourceArray.count
    // TODO manage multi accounts
    
    favoritesCells = [[NSMutableArray alloc] init];
    conversationCells = [[NSMutableArray alloc] init];
    lowPriorityCells = [[NSMutableArray alloc] init];
    
    favoritesPos = conversationPos = lowPriorityPos = -1;
    sectionsCount = 0;
    
    if (displayedRecentsDataSourceArray.count > 0)
    {
        MXKSessionRecentsDataSource *recentsDataSource = [displayedRecentsDataSourceArray objectAtIndex:0];
        NSInteger count = recentsDataSource.numberOfCells;
        
        for(int index = 0; index < count; index++)
        {
            id<MXKRecentCellDataStoring> recentCellDataStoring = [recentsDataSource cellDataAtIndex:index];
            MXRoom* room = recentCellDataStoring.roomDataSource.room;
            
            NSDictionary* tags = room.accountData.tags;
            
            if (tags && [tags objectForKey:kMXRoomTagFavourite])
            {
                [favoritesCells addObject:recentCellDataStoring];
            }
            else  if (tags && [tags objectForKey:kMXRoomTagLowPriority])
            {
                [lowPriorityCells addObject:recentCellDataStoring];
            }
            else
            {
                [conversationCells addObject:recentCellDataStoring];
            }
        }
        
        int pos = 0;
        
        if (favoritesCells.count > 0)
        {
            favoritesPos = pos;
            pos++;
        }
        
        if (conversationCells.count > 0)
        {
            conversationPos = pos;
            pos++;
        }
        
        if (lowPriorityCells.count > 0)
        {
            lowPriorityPos = pos;
            pos++;
        }
        
        sectionsCount = pos;
    }
}


- (void)dataSource:(MXKDataSource*)dataSource didCellChange:(id)changes
{
    // Call super to keep update readyRecentsDataSourceArray.
    [super dataSource:dataSource didCellChange:changes];
    
    [self refreshRoomsSections];
}

#pragma mark - Override MXKDataSource

- (void)destroy
{
    [super destroy];
}

@end
