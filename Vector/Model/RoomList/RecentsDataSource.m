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

#import "EventFormatter.h"

#import "VectorDesignValues.h"

#import "InviteRecentTableViewCell.h"

#import "MXRoom+Vector.h"

#import "RecentCellData.h"

@interface RecentsDataSource()
{
    NSMutableArray* invitesCellDataArray;
    NSMutableArray* favoriteCellDataArray;
    NSMutableArray* conversationCellDataArray;
    NSMutableArray* lowPriorityCellDataArray;
    
    NSInteger invitesSection;
    NSInteger favoritesSection;
    NSInteger conversationSection;
    NSInteger lowPrioritySection;
    NSInteger sectionsCount;
    
    NSMutableDictionary<NSString*, id> *roomTagsListenerByUserId;
}
@end

@implementation RecentsDataSource
@synthesize onRoomInvitationReject, onRoomInvitationAccept;
@synthesize hiddenCellIndexPath, droppingCellIndexPath, droppingCellBackGroundView;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        // Replace event formatter
        self.eventFormatter = [[EventFormatter alloc] initWithMatrixSession:self.mxSession];
        
        favoriteCellDataArray = [[NSMutableArray alloc] init];
        conversationCellDataArray = [[NSMutableArray alloc] init];
        lowPriorityCellDataArray = [[NSMutableArray alloc] init];
        
        invitesSection = -1;
        favoritesSection = -1;
        conversationSection = -1;
        lowPrioritySection = -1;
        sectionsCount = 0;
        
        roomTagsListenerByUserId = [[NSMutableDictionary alloc] init];
        
        // Set default data and view classes
        [self registerCellDataClass:RecentCellData.class forCellIdentifier:kMXKRecentCellIdentifier];
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
                                                                        
                                                                        [self refreshRoomsSectionsAndReload];
                                                                    
                                                                    });
                                                                }
                                                                
                                                            }];
        
        [roomTagsListenerByUserId setObject:roomTagsListener forKey:self.mxSession.myUser.userId];
    }
}

- (BOOL)isRoomNotifiedAtIndexPath:(NSIndexPath *)indexPath
{
    MXRoom* room = [self getRoomAtIndexPath:indexPath];

    if (room)
    {
        return !room.areRoomNotificationsMuted;
    }
    
    return YES;
}

- (void)muteRoomNotifications:(BOOL)mute atIndexPath:(NSIndexPath *)indexPath
{
    MXRoom* room = [self getRoomAtIndexPath:indexPath];
    
    // sanity check
    if (room)
    {
        [room toggleRoomNotifications:mute];
    }
}

- (void)refreshRoomsSectionsAndReload
{
    // Refresh is disabled during drag&drop animation"
    if (!self.droppingCellIndexPath)
    {
        [self refreshRoomsSections];
        
        // And inform the delegate about the update
        [self.delegate dataSource:self didCellChange:nil];
    }
}

- (void)didMXSessionInviteRoomUpdate:(NSNotification *)notif
{
    MXSession *mxSession = notif.object;
    if (mxSession == self.mxSession)
    {
        [self refreshRoomsSectionsAndReload];
    }
}

#pragma mark - UITableViewDataSource

/**
 Return the header height from the section.
 */
- (CGFloat)heightForHeaderInSection:(NSInteger)section
{
    if ((section == invitesSection) || (section == favoritesSection) || (section == conversationSection) || (section == lowPrioritySection))
    {
        return 30.0f;
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

- (BOOL)isMovingCellSection:(NSInteger)section
{
    return self.droppingCellIndexPath && (self.droppingCellIndexPath.section == section);
}

- (BOOL)isHiddenCellSection:(NSInteger)section
{
    return self.hiddenCellIndexPath && (self.hiddenCellIndexPath.section == section);
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
    else if (section == invitesSection)
    {
        count = invitesCellDataArray.count;
    }
    
    if ([self isMovingCellSection:section])
    {
        count++;
    }
    
    if ([self isHiddenCellSection:section])
    {
        count--;
    }
    
    return count;
}

- (UIView *)viewForHeaderInSection:(NSInteger)section withFrame:(CGRect)frame
{
    // add multi accounts section management
    
    if ((section == favoritesSection) || (section == conversationSection) || (section == lowPrioritySection) || (section == invitesSection))
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
        else if (section == invitesSection)
        {
            text = NSLocalizedStringFromTable(@"room_recents_invites", @"Vector", nil);
        }
    
        label.text = [NSString stringWithFormat:@"   %@", text];
        label.font = [UIFont boldSystemFontOfSize:15.0];
        label.backgroundColor = VECTOR_LIGHT_GRAY_COLOR;
        
        return label;
    }
    
    return [super viewForHeaderInSection:section withFrame:frame];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)anIndexPath
{
    NSIndexPath* indexPath = anIndexPath;
    
    if (self.droppingCellIndexPath  && (self.droppingCellIndexPath.section == indexPath.section))
    {
        if ([anIndexPath isEqual:self.droppingCellIndexPath])
        {
            static NSString* cellIdentifier = @"VectorRecentsMovingCell";
            
            UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"VectorRecentsMovingCell"];
            
            // add an imageview of the cell.
            // The image is a shot of the genuine cell.
            // Thus, this cell has the same look as the genuine cell withourt computing it.
            UIImageView* imageView = [cell viewWithTag:[cellIdentifier hash]];
            
            if (!imageView || (imageView != self.droppingCellBackGroundView))
            {
                if (imageView)
                {
                    [imageView removeFromSuperview];
                }
                self.droppingCellBackGroundView.tag = [cellIdentifier hash];
                [cell.contentView addSubview:self.droppingCellBackGroundView];
            }
            
            self.droppingCellBackGroundView.frame = self.droppingCellBackGroundView.frame;
            cell.contentView.backgroundColor = [UIColor clearColor];
            cell.backgroundColor = [UIColor clearColor];
            
            return cell;
        }
        
        if (anIndexPath.row > self.droppingCellIndexPath.row)
        {
            indexPath = [NSIndexPath indexPathForRow:anIndexPath.row-1 inSection:anIndexPath.section];
        }
    }
    
    if (self.hiddenCellIndexPath && [anIndexPath isEqual:self.hiddenCellIndexPath])
    {
        indexPath = [NSIndexPath indexPathForRow:anIndexPath.row-1 inSection:anIndexPath.section];
    }
    
    UITableViewCell* cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    // on invite cell, add listeners on accept / reject buttons
    if (cell && [cell isKindOfClass:[InviteRecentTableViewCell class]])
    {
        id<MXKRecentCellDataStoring> roomData = [self cellDataAtIndexPath:indexPath];
        InviteRecentTableViewCell* inviteRecentTableViewCell = (InviteRecentTableViewCell*)cell;
        
        inviteRecentTableViewCell.onRejectClick = ^(){
            if (self.onRoomInvitationReject)
            {
                self.onRoomInvitationReject(roomData.roomDataSource.room);
            }
        };
        
        inviteRecentTableViewCell.onJoinClick = ^(){
            if (self.onRoomInvitationAccept)
            {
                self.onRoomInvitationAccept(roomData.roomDataSource.room);
            }
        };
    }
    
    return cell;
}

- (id<MXKRecentCellDataStoring>)cellDataAtIndexPath:(NSIndexPath *)anIndexPath
{
    id<MXKRecentCellDataStoring> cellData = nil;
    NSInteger row = anIndexPath.row;
    NSInteger section = anIndexPath.section;
    
    if (self.droppingCellIndexPath  && (self.droppingCellIndexPath.section == section))
    {
        if (anIndexPath.row > self.droppingCellIndexPath.row)
        {
            row = anIndexPath.row - 1;
        }
    }
    
    if (section == favoritesSection)
    {
        cellData = [favoriteCellDataArray objectAtIndex:row];
    }
    else if (section== conversationSection)
    {
        cellData = [conversationCellDataArray objectAtIndex:row];
    }
    else if (section == lowPrioritySection)
    {
        cellData = [lowPriorityCellDataArray objectAtIndex:row];
    }
    else if (section == invitesSection)
    {
        cellData = [invitesCellDataArray objectAtIndex:row];
    }
    
    return cellData;
}

- (CGFloat)cellHeightAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.droppingCellIndexPath && [indexPath isEqual:self.droppingCellIndexPath])
    {
        return self.droppingCellBackGroundView.frame.size.height;
    }
    
    // Override this method here to use our own cellDataAtIndexPath
    id<MXKRecentCellDataStoring> cellData = [self cellDataAtIndexPath:indexPath];
    
    if (cellData && self.delegate)
    {
        Class<MXKCellRendering> class = [self.delegate cellViewClassForCellData:cellData];
        
        return [class heightForCellData:cellData withMaximumWidth:0];
    }

    return 0;
}

- (NSInteger)cellIndexPosWithRoomId:(NSString*)roomId andMatrixSession:(MXSession*)matrixSession within:(NSMutableArray*)cellDataArray
{
    if (roomId && matrixSession && cellDataArray.count)
    {
        for (int index = 0; index < cellDataArray.count; index++)
        {
            id<MXKRecentCellDataStoring> cellDataStoring = [cellDataArray objectAtIndex:index];

            if ([roomId isEqualToString:cellDataStoring.roomDataSource.roomId] && (matrixSession == cellDataStoring.roomDataSource.mxSession))
            {
                return index;
            }
        }
    }

    return NSNotFound;
}

- (NSIndexPath*)cellIndexPathWithRoomId:(NSString*)roomId andMatrixSession:(MXSession*)matrixSession
{
    NSIndexPath *indexPath = nil;
    NSInteger index = NSNotFound;
    
    if (!indexPath && (invitesSection >= 0))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:invitesCellDataArray];
        
        if (index != NSNotFound)
        {
            indexPath = [NSIndexPath indexPathForRow:index inSection:invitesSection];
        }
    }
    
    if (!indexPath && (favoritesSection >= 0))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:favoriteCellDataArray];
        
        if (index != NSNotFound)
        {
            indexPath = [NSIndexPath indexPathForRow:index inSection:favoritesSection];
        }
    }
    
    if (!indexPath && (conversationSection >= 0))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:conversationCellDataArray];
        
        if (index != NSNotFound)
        {
            indexPath = [NSIndexPath indexPathForRow:index inSection:conversationSection];
        }
    }
    
    if (!indexPath && (lowPrioritySection >= 0))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:lowPriorityCellDataArray];
        
        if (index != NSNotFound)
        {
            indexPath = [NSIndexPath indexPathForRow:index inSection:lowPrioritySection];
        }
    }
    
    if (!indexPath)
    {
        indexPath = [super cellIndexPathWithRoomId:roomId andMatrixSession:matrixSession];
    }
    
    return indexPath;
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
    
    favoritesSection = conversationSection = lowPrioritySection = invitesSection = -1;
    sectionsCount = 0;

    if (displayedRecentsDataSourceArray.count > 0)
    {
        MXKSessionRecentsDataSource *recentsDataSource = [displayedRecentsDataSourceArray objectAtIndex:0];
        MXSession* session = recentsDataSource.mxSession;
        
        NSArray* sortedInvitesRooms = [session invitedRooms];
        NSArray* sortedFavRooms = [session roomsWithTag:kMXRoomTagFavourite];
        NSArray* sortedLowPriorRooms = [session roomsWithTag:kMXRoomTagLowPriority];
        
        invitesCellDataArray = [self createEmptyArray:sortedInvitesRooms.count];
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
            else  if ((pos = [sortedInvitesRooms indexOfObject:room]) != NSNotFound)
            {
                if (pos < invitesCellDataArray.count)
                {
                    [invitesCellDataArray replaceObjectAtIndex:pos withObject:recentCellDataStoring];
                }
            }
            else
            {
                [conversationCellDataArray addObject:recentCellDataStoring];
            }
        }
        
        int sectionIndex = 0;
        
        [invitesCellDataArray removeObject:[NSNull null]];
        if (invitesCellDataArray.count > 0)
        {
            invitesSection = sectionIndex;
            sectionIndex++;
        }
        
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
    // Refresh is disabled during drag&drop animation
    if (self.droppingCellIndexPath)
    {
        return;
    }
    
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
    
    // refresh the sections
    [self refreshRoomsSections];
    
    // Call super to keep update readyRecentsDataSourceArray.
    [super dataSource:dataSource didCellChange:changes];
}

#pragma mark - Override MXKDataSource

- (void)destroy
{
    [super destroy];
}


#pragma mark - drag and drop managemenent

- (BOOL)isDraggableCellAt:(NSIndexPath*)path
{
    return (path && ((path.section == favoritesSection) || (path.section == lowPrioritySection) || (path.section == conversationSection)));
}

- (BOOL)canCellMoveFrom:(NSIndexPath*)oldPath to:(NSIndexPath*)newPath
{
    BOOL res = [self isDraggableCellAt:oldPath] && [self isDraggableCellAt:newPath];
    
    // the both index pathes are movable
    if (res)
    {
        // only the favorites cell can be moved within the same section
        res &= (oldPath.section == favoritesSection) || (newPath.section != oldPath.section);
        
        // other cases ?
    }
    
    return res;
}

- (NSString*)roomTagAt:(NSIndexPath*)path
{
    if (path.section == favoritesSection)
    {
        return kMXRoomTagFavourite;
    }
    else if (path.section == lowPrioritySection)
    {
        return kMXRoomTagLowPriority;
    }
    
    return nil;
}

- (void)moveRoomCell:(MXRoom*)room from:(NSIndexPath*)oldPath to:(NSIndexPath*)newPath success:(void (^)())moveSuccess failure:(void (^)(NSError *error))moveFailure;
{
    NSLog(@"[RecentsDataSource] moveCellFrom (%d, %d) to (%d, %d)", oldPath.section, oldPath.row, newPath.section, newPath.row);
    
    if ([self canCellMoveFrom:oldPath to:newPath] && ![newPath isEqual:oldPath])
    {
        NSString* oldRoomTag = [self roomTagAt:oldPath];
        NSString* dstRoomTag = [self roomTagAt:newPath];
        NSUInteger oldPos = (oldPath.section == newPath.section) ? oldPath.row : NSNotFound;
        
        NSString* tagOrder = [room.mxSession tagOrderToBeAtIndex:newPath.row from:oldPos withTag:dstRoomTag];
        
        NSLog(@"[RecentsDataSource] Update the room %@ [%@] tag from %@ to %@ with tag order %@", room.state.roomId, room.state.displayname, oldRoomTag, dstRoomTag, tagOrder);
        
        [room replaceTag:oldRoomTag
                   byTag:dstRoomTag
               withOrder:tagOrder
                 success: ^{
                     
                     NSLog(@"[RecentsDataSource] move is done");
                     
                     if (moveSuccess)
                     {
                         moveSuccess();
                     }

                     // wait the server echo to reload the tableview.
                     
                 } failure:^(NSError *error) {
                     
                     NSLog(@"[RecentsDataSource] Failed to update the tag %@ of room (%@) failed: %@", dstRoomTag, room.state.roomId, error);
                     
                     if (moveFailure)
                     {
                         moveFailure(error);
                     }
                     
                     [self refreshRoomsSectionsAndReload];
                     
                     // Notify MatrixKit user
                     [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                 }];
    }
    else
    {
        NSLog(@"[RecentsDataSource] cannot move this cell");
        
        if (moveFailure)
        {
            moveFailure(nil);
        }
        
        [self refreshRoomsSectionsAndReload];
    }
}

@end
