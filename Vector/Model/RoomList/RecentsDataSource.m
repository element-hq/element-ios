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
    NSMutableArray* favoriteCellDataArray;
    NSMutableArray* conversationCellDataArray;
    NSMutableArray* lowPriorityCellDataArray;
    
    NSInteger favoritesSection;
    NSInteger conversationSection;
    NSInteger lowPrioritySection;
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
        
        favoriteCellDataArray = [[NSMutableArray alloc] init];
        conversationCellDataArray = [[NSMutableArray alloc] init];
        lowPriorityCellDataArray = [[NSMutableArray alloc] init];
        
        favoritesSection = -1;
        conversationSection = -1;
        lowPrioritySection = -1;
        sectionsCount = 0;
        
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
    if ((section == favoritesSection) || (section == conversationSection) || (section == lowPrioritySection))
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
    
    if (section == favoritesSection)
    {
        count = favoriteCellDataArray.count;
    }
    else if (section == conversationSection)
    {
        count = conversationCellDataArray.count;
    }
    else if (section == lowPrioritySection)
    {
        count = lowPriorityCellDataArray.count;
    }

    return count;
}

- (UIView *)viewForHeaderInSection:(NSInteger)section withFrame:(CGRect)frame
{
    // add multi accounts section management
    
    if ((section == favoritesSection) || (section == conversationSection) || (section == lowPrioritySection))
    {
        UILabel* label = [[UILabel alloc] initWithFrame:frame];
        
        NSString* text = @"";
        
        if (section == favoritesSection)
        {
            text = NSLocalizedStringFromTable(@"room_recents_favourites", @"Vector", nil);
        }
        else if (section == conversationSection)
        {
            text = NSLocalizedStringFromTable(@"room_recents_conversations", @"Vector", nil);
        }
        else if (section == lowPrioritySection)
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
    
    if (indexPath.section == favoritesSection)
    {
        cellData = [favoriteCellDataArray objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == conversationSection)
    {
        cellData = [conversationCellDataArray objectAtIndex:indexPath.row];
    }
    else if (indexPath.section == lowPrioritySection)
    {
        cellData = [lowPriorityCellDataArray objectAtIndex:indexPath.row];
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

// create an array filled with NSNull and with the same size as sourceArray
- (NSMutableArray*)createEmptyArray:(NSUInteger)count
{
    NSMutableArray* array = [[NSMutableArray alloc] init];
    
    for(NSUInteger i = 0; i < count; i++)
    {
        [array addObject:[NSNull null]];
    }
    
    return array;
}

- (void)refreshRoomsSections
{
    // FIXME manage multi accounts
    
    favoriteCellDataArray = [[NSMutableArray alloc] init];
    conversationCellDataArray = [[NSMutableArray alloc] init];
    lowPriorityCellDataArray = [[NSMutableArray alloc] init];
    
    favoritesSection = conversationSection = lowPrioritySection = -1;
    sectionsCount = 0;

    if (displayedRecentsDataSourceArray.count > 0)
    {
        MXKSessionRecentsDataSource *recentsDataSource = [displayedRecentsDataSourceArray objectAtIndex:0];
        MXSession* session = recentsDataSource.mxSession;
        
        NSArray* sortedFavRooms = [session roomsWithTag:kMXRoomTagFavourite];
        NSArray* sortedLowPriorRooms = [session roomsWithTag:kMXRoomTagLowPriority];
        
        favoriteCellDataArray = [self createEmptyArray:sortedFavRooms.count];
        lowPriorityCellDataArray = [self createEmptyArray:sortedLowPriorRooms.count];
        
        NSInteger count = recentsDataSource.numberOfCells;
        
        for(int index = 0; index < count; index++)
        {
            NSUInteger pos;
            id<MXKRecentCellDataStoring> recentCellDataStoring = [recentsDataSource cellDataAtIndex:index];
            MXRoom* room = recentCellDataStoring.roomDataSource.room;

            if ((pos = [sortedFavRooms indexOfObject:room]) != NSNotFound)
            {
                if (pos < favoriteCellDataArray.count)
                {
                    [favoriteCellDataArray replaceObjectAtIndex:pos withObject:recentCellDataStoring];
                }
            }
            else  if ((pos = [sortedLowPriorRooms indexOfObject:room]) != NSNotFound)
            {
                if (pos < lowPriorityCellDataArray.count)
                {
                    [lowPriorityCellDataArray replaceObjectAtIndex:pos withObject:recentCellDataStoring];
                }
            }
            else
            {
                [conversationCellDataArray addObject:recentCellDataStoring];
            }
        }
        
        int sectionIndex = 0;
        
        [favoriteCellDataArray removeObject:[NSNull null]];
        if (favoriteCellDataArray.count > 0)
        {
            favoritesSection = sectionIndex;
            sectionIndex++;
        }
        
        [conversationCellDataArray removeObject:[NSNull null]];
        if (conversationCellDataArray.count > 0)
        {
            conversationSection = sectionIndex;
            sectionIndex++;
        }
        
        [lowPriorityCellDataArray removeObject:[NSNull null]];
        if (lowPriorityCellDataArray.count > 0)
        {
            lowPrioritySection = sectionIndex;
            sectionIndex++;
        }
        
        sectionsCount = sectionIndex;
    }
}

- (void)dataSource:(MXKDataSource*)dataSource didCellChange:(id)changes
{
    // FIXME : manage multi accounts
    // to manage multi accounts
    // this method in MXKInterleavedRecentsDataSource must be split in two parts
    // 1 - the intervealing cells method
    // 2 - [super dataSource:dataSource didCellChange:changes] call.
    // the [self refreshRoomsSections] call should be done at the end of the 1- method
    // so a dedicated method must be implemented in MXKInterleavedRecentsDataSource
    // this class will inherit of this new method
    // 1 - call [super thisNewMethod]
    // 2 - call [self refreshRoomsSections]
    
    // refresh the 
    [self refreshRoomsSections];
    
    // Call super to keep update readyRecentsDataSourceArray.
    [super dataSource:dataSource didCellChange:changes];
}

#pragma mark - Override MXKDataSource

- (void)destroy
{
    [super destroy];
}

@end
