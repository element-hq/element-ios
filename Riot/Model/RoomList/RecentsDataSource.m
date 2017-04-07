/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
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

#import "RecentCellData.h"

#import "RiotDesignValues.h"

#import "MXRoom+Riot.h"

#import "DirectoryRecentTableViewCell.h"

#define RECENTSDATASOURCE_SECTION_DIRECTORY     0x01
#define RECENTSDATASOURCE_SECTION_INVITES       0x02
#define RECENTSDATASOURCE_SECTION_FAVORITES     0x04
#define RECENTSDATASOURCE_SECTION_CONVERSATIONS 0x08
#define RECENTSDATASOURCE_SECTION_LOWPRIORITY   0x10

@interface RecentsDataSource()
{
    NSMutableArray* invitesCellDataArray;
    NSMutableArray* favoriteCellDataArray;
    NSMutableArray* conversationCellDataArray;
    NSMutableArray* lowPriorityCellDataArray;
    
    NSInteger shrinkedSectionsBitMask;
    
    NSMutableDictionary<NSString*, id> *roomTagsListenerByUserId;
    
    // Timer to not refresh publicRoomsDirectoryDataSource on every keystroke.
    NSTimer *publicRoomsTriggerTimer;
}
@end

@implementation RecentsDataSource
@synthesize hiddenCellIndexPath, droppingCellIndexPath, droppingCellBackGroundView;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        invitesCellDataArray = [[NSMutableArray alloc] init];
        favoriteCellDataArray = [[NSMutableArray alloc] init];
        lowPriorityCellDataArray = [[NSMutableArray alloc] init];
        conversationCellDataArray = [[NSMutableArray alloc] init];

        directorySection = -1;
        invitesSection = -1;
        favoritesSection = -1;
        conversationSection = -1;
        lowPrioritySection = -1;
        sectionsCount = 0;
        
        _areSectionsShrinkable = NO;
        shrinkedSectionsBitMask = 0;
        
        roomTagsListenerByUserId = [[NSMutableDictionary alloc] init];
        
        // Set default data and view classes
        [self registerCellDataClass:RecentCellData.class forCellIdentifier:kMXKRecentCellIdentifier];
    }
    return self;
}

#pragma mark -

- (void)setDelegate:(id<MXKDataSourceDelegate>)delegate andRecentsDataSourceMode:(RecentsDataSourceMode)recentsDataSourceMode
{
    self.delegate = delegate;
    
    self.recentsDataSourceMode = recentsDataSourceMode;
}

- (void)setRecentsDataSourceMode:(RecentsDataSourceMode)recentsDataSourceMode
{
    _recentsDataSourceMode = recentsDataSourceMode;
    
    [self forceRefresh];
}

#pragma mark -

- (MXKSessionRecentsDataSource *)addMatrixSession:(MXSession *)mxSession
{
    MXKSessionRecentsDataSource *recentsDataSource = [super addMatrixSession:mxSession];

    // Initialise the public room directory data source
    // Note that it is single matrix session only for now
    if (!_publicRoomsDirectoryDataSource)
    {
        _publicRoomsDirectoryDataSource = [[PublicRoomsDirectoryDataSource alloc] initWithMatrixSession:mxSession];
        _publicRoomsDirectoryDataSource.delegate = self;
    }
    
    return recentsDataSource;
}

- (void)removeMatrixSession:(MXSession*)matrixSession
{
    [super removeMatrixSession:matrixSession];
    
    // sanity check
    if (matrixSession.myUser && matrixSession.myUser.userId)
    {
        id roomTagListener = [roomTagsListenerByUserId objectForKey:matrixSession.myUser.userId];
        
        if (roomTagListener)
        {
            [matrixSession removeListener:roomTagListener];
            [roomTagsListenerByUserId removeObjectForKey:matrixSession.myUser.userId];
        }
    }
    
    if (_publicRoomsDirectoryDataSource.mxSession == matrixSession)
    {
        [_publicRoomsDirectoryDataSource destroy];
        _publicRoomsDirectoryDataSource = nil;
    }
}

- (void)dataSource:(MXKDataSource*)dataSource didStateChange:(MXKDataSourceState)aState
{
    if (dataSource == _publicRoomsDirectoryDataSource)
    {
        if (-1 != directorySection)
        {
            // TODO: We should only update the directory section
            [self.delegate dataSource:self didCellChange:nil];
        }
    }
    else
    {
        [super dataSource:dataSource didStateChange:aState];

        if ((aState == MXKDataSourceStateReady) && dataSource.mxSession.myUser.userId)
        {
            // Register the room tags updates to refresh the favorites order
            id roomTagsListener = [dataSource.mxSession listenToEventsOfTypes:@[kMXEventTypeStringRoomTag]
                                                                onEvent:^(MXEvent *event, MXTimelineDirection direction, id customObject) {

                                                                    // Consider only live event
                                                                    if (direction == MXTimelineDirectionForwards)
                                                                    {
                                                                        dispatch_async(dispatch_get_main_queue(), ^{

                                                                            [self forceRefresh];

                                                                        });
                                                                    }

                                                                }];

            [roomTagsListenerByUserId setObject:roomTagsListener forKey:dataSource.mxSession.myUser.userId];
        }
    }
}

- (void)forceRefresh
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
    if ([self.mxSessions indexOfObject:mxSession] != NSNotFound)
    {
        [self forceRefresh];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Check whether all data sources are ready before rendering recents
    if (self.state == MXKDataSourceStateReady)
    {
        // Return the last updated number of sections.
        return sectionsCount;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count = 0;

    if (section == favoritesSection && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_FAVORITES))
    {
        count = favoriteCellDataArray.count;
    }
    else if (section == conversationSection && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_CONVERSATIONS))
    {
        count = conversationCellDataArray.count;
    }
    else if (section == directorySection && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_DIRECTORY))
    {
        count = [_publicRoomsDirectoryDataSource tableView:tableView numberOfRowsInSection:section];
    }
    else if (section == lowPrioritySection && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_LOWPRIORITY))
    {
        count = lowPriorityCellDataArray.count;
    }
    else if (section == invitesSection && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_INVITES))
    {
        count = invitesCellDataArray.count;
    }
    
    // Adjust this count according to the potential dragged cell.
    if ([self isMovingCellSection:section])
    {
        count++;
    }
    
    if (count && [self isHiddenCellSection:section])
    {
        count--;
    }
    
    return count;
}

- (UIView *)viewForHeaderInSection:(NSInteger)section withFrame:(CGRect)frame
{
    UIView *sectionHeader = nil;
    
    if (section < sectionsCount)
    {
        NSString* sectionTitle = @"";
        NSInteger sectionBitwise = 0;
        UIImageView *chevronView;
        
        if (section == favoritesSection)
        {
            sectionTitle = NSLocalizedStringFromTable(@"room_recents_favourites", @"Vector", nil);
            sectionBitwise = _areSectionsShrinkable ? RECENTSDATASOURCE_SECTION_FAVORITES : 0;
        }
        else if (section == conversationSection)
        {
            sectionTitle = NSLocalizedStringFromTable(@"room_recents_conversations", @"Vector", nil);
            sectionBitwise = _areSectionsShrinkable ? RECENTSDATASOURCE_SECTION_CONVERSATIONS : 0;
        }
        else if (section == directorySection)
        {
            sectionTitle = NSLocalizedStringFromTable(@"room_recents_directory", @"Vector", nil);
            sectionBitwise = _areSectionsShrinkable ? RECENTSDATASOURCE_SECTION_CONVERSATIONS : 0;
        }
        else if (section == lowPrioritySection)
        {
            sectionTitle = NSLocalizedStringFromTable(@"room_recents_low_priority", @"Vector", nil);
            sectionBitwise = _areSectionsShrinkable ? RECENTSDATASOURCE_SECTION_LOWPRIORITY : 0;
        }
        else if (section == invitesSection)
        {
            sectionTitle = NSLocalizedStringFromTable(@"room_recents_invites", @"Vector", nil);
            sectionBitwise = _areSectionsShrinkable ? RECENTSDATASOURCE_SECTION_INVITES : 0;
        }
        
        sectionHeader = [[UIView alloc] initWithFrame:frame];
        sectionHeader.backgroundColor = kRiotColorLightGrey;
        
        if (sectionBitwise)
        {
            // Add shrink button
            UIButton *shrinkButton = [UIButton buttonWithType:UIButtonTypeCustom];
            frame.origin.x = frame.origin.y = 0;
            shrinkButton.frame = frame;
            shrinkButton.backgroundColor = [UIColor clearColor];
            [shrinkButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            shrinkButton.tag = sectionBitwise;
            [sectionHeader addSubview:shrinkButton];
            sectionHeader.userInteractionEnabled = YES;
            
            // Add shrink icon
            UIImage *chevron;
            if (shrinkedSectionsBitMask & sectionBitwise)
            {
                chevron = [UIImage imageNamed:@"disclosure_icon"];
            }
            else
            {
                chevron = [UIImage imageNamed:@"shrink_icon"];
            }
            chevronView = [[UIImageView alloc] initWithImage:chevron];
            chevronView.contentMode = UIViewContentModeCenter;
            frame = chevronView.frame;
            frame.origin.x = sectionHeader.frame.size.width - frame.size.width - 16;
            frame.origin.y = (sectionHeader.frame.size.height - frame.size.height) / 2;
            chevronView.frame = frame;
            [sectionHeader addSubview:chevronView];
            chevronView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
        }
        
        // Add label
        frame = sectionHeader.frame;
        frame.origin.x = 20;
        frame.origin.y = 5;
        frame.size.width = chevronView ? chevronView.frame.origin.x - 10 : sectionHeader.frame.size.width - 10;
        frame.size.height -= 10;
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
        headerLabel.font = [UIFont boldSystemFontOfSize:15.0];
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.text = sectionTitle;
        [sectionHeader addSubview:headerLabel];
    }
    
    return sectionHeader;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == directorySection)
    {
        NSIndexPath *indexPathInPublicRooms = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
        return [_publicRoomsDirectoryDataSource tableView:tableView cellForRowAtIndexPath:indexPathInPublicRooms];
    }
    else if (self.droppingCellIndexPath && [indexPath isEqual:self.droppingCellIndexPath])
    {
        static NSString* cellIdentifier = @"RiotRecentsMovingCell";
        
        UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"RiotRecentsMovingCell"];
        
        // add an imageview of the cell.
        // The image is a shot of the genuine cell.
        // Thus, this cell has the same look as the genuine cell without computing it.
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
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (id<MXKRecentCellDataStoring>)cellDataAtIndexPath:(NSIndexPath *)indexPath
{
    id<MXKRecentCellDataStoring> cellData = nil;
    NSUInteger cellDataIndex = indexPath.row;
    NSInteger tableSection = indexPath.section;
    
    // Compute the actual cell data index by taking into account the current droppingCellIndexPath and hiddenCellIndexPath (if any).
    if ([self isMovingCellSection:tableSection] && (cellDataIndex > self.droppingCellIndexPath.row))
    {
        cellDataIndex --;
    }
    if ([self isHiddenCellSection:tableSection] && (cellDataIndex >= self.hiddenCellIndexPath.row))
    {
        cellDataIndex ++;
    }
    
    if (tableSection == favoritesSection)
    {
        if (cellDataIndex < favoriteCellDataArray.count)
        {
            cellData = [favoriteCellDataArray objectAtIndex:cellDataIndex];
        }
    }
    else if (tableSection== conversationSection)
    {
        if (cellDataIndex < conversationCellDataArray.count)
        {
            cellData = [conversationCellDataArray objectAtIndex:cellDataIndex];
        }
    }
    else if (tableSection == lowPrioritySection)
    {
        if (cellDataIndex < lowPriorityCellDataArray.count)
        {
            cellData = [lowPriorityCellDataArray objectAtIndex:cellDataIndex];
        }
    }
    else if (tableSection == invitesSection)
    {
        if (cellDataIndex < invitesCellDataArray.count)
        {
            cellData = [invitesCellDataArray objectAtIndex:cellDataIndex];
        }
    }
    
    return cellData;
}

- (CGFloat)cellHeightAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == directorySection)
    {
        return DirectoryRecentTableViewCell.cellHeight;
    }
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

#pragma mark -

- (NSInteger)cellIndexPosWithRoomId:(NSString*)roomId andMatrixSession:(MXSession*)matrixSession within:(NSMutableArray*)cellDataArray
{
    if (roomId && matrixSession && cellDataArray.count)
    {
        for (int index = 0; index < cellDataArray.count; index++)
        {
            id<MXKRecentCellDataStoring> cellDataStoring = [cellDataArray objectAtIndex:index];

            if ([roomId isEqualToString:cellDataStoring.roomSummary.roomId] && (matrixSession == cellDataStoring.roomSummary.room.mxSession))
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
    NSInteger index;
    
    if (invitesSection >= 0)
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:invitesCellDataArray];
        
        if (index != NSNotFound)
        {
            // Check whether the invitations are shrinked
            if (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_INVITES)
            {
                return nil;
            }
            indexPath = [NSIndexPath indexPathForRow:index inSection:invitesSection];
        }
    }
    
    if (!indexPath && (favoritesSection >= 0))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:favoriteCellDataArray];
        
        if (index != NSNotFound)
        {
            // Check whether the favorites are shrinked
            if (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_FAVORITES)
            {
                return nil;
            }
            indexPath = [NSIndexPath indexPathForRow:index inSection:favoritesSection];
        }
    }
    
    if (!indexPath && (conversationSection >= 0))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:conversationCellDataArray];
        
        if (index != NSNotFound)
        {
            // Check whether the conversations are shrinked
            if (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_CONVERSATIONS)
            {
                return nil;
            }
            indexPath = [NSIndexPath indexPathForRow:index inSection:conversationSection];
        }
    }
    
    if (!indexPath && (lowPrioritySection >= 0))
    {
        index = [self cellIndexPosWithRoomId:roomId andMatrixSession:matrixSession within:lowPriorityCellDataArray];
        
        if (index != NSNotFound)
        {
            // Check whether the low priority rooms are shrinked
            if (shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_LOWPRIORITY)
            {
                return nil;
            }
            indexPath = [NSIndexPath indexPathForRow:index inSection:lowPrioritySection];
        }
    }
    
    return indexPath;
}


#pragma mark - MXKDataSourceDelegate

- (void)refreshRoomsSections
{
    [invitesCellDataArray removeAllObjects];
    [favoriteCellDataArray removeAllObjects];
    [conversationCellDataArray removeAllObjects];
    [lowPriorityCellDataArray removeAllObjects];
    
    directorySection = favoritesSection = conversationSection = lowPrioritySection = invitesSection = -1;
    sectionsCount = 0;
    
    if (displayedRecentsDataSourceArray.count > 0)
    {
        // FIXME manage multi accounts
        MXKSessionRecentsDataSource *recentsDataSource = [displayedRecentsDataSourceArray objectAtIndex:0];
        MXSession* session = recentsDataSource.mxSession;
        
        NSInteger count = recentsDataSource.numberOfCells;
        
        if (_recentsDataSourceMode == RecentsDataSourceModeHome)
        {
            for (int index = 0; index < count; index++)
            {
                id<MXKRecentCellDataStoring> recentCellDataStoring = [recentsDataSource cellDataAtIndex:index];
                MXRoom* room = recentCellDataStoring.roomSummary.room;
                
                if (room.accountData.tags[kMXRoomTagFavourite])
                {
                    [favoriteCellDataArray addObject:recentCellDataStoring];
                }
                else if (room.accountData.tags[kMXRoomTagLowPriority])
                {
                    [lowPriorityCellDataArray addObject:recentCellDataStoring];
                }
                else if (room.state.membership == MXMembershipInvite)
                {
                    [invitesCellDataArray addObject:recentCellDataStoring];
                }
                else
                {
                    [conversationCellDataArray addObject:recentCellDataStoring];
                }
            }
        }
        else if (_recentsDataSourceMode == RecentsDataSourceModeFavourites)
        {
            for (int index = 0; index < count; index++)
            {
                id<MXKRecentCellDataStoring> recentCellDataStoring = [recentsDataSource cellDataAtIndex:index];
                MXRoom* room = recentCellDataStoring.roomSummary.room;
                
                // Keep only the favourites rooms.
                if (room.accountData.tags[kMXRoomTagFavourite])
                {
                    [favoriteCellDataArray addObject:recentCellDataStoring];
                }
            }
        }
        else if (_recentsDataSourceMode == RecentsDataSourceModePeople)
        {
            for (int index = 0; index < count; index++)
            {
                id<MXKRecentCellDataStoring> recentCellDataStoring = [recentsDataSource cellDataAtIndex:index];
                MXRoom* room = recentCellDataStoring.roomSummary.room;
                
                // Keep only the direct rooms.
                if (room.isDirect)
                {
                    if (room.state.membership == MXMembershipInvite)
                    {
                        [invitesCellDataArray addObject:recentCellDataStoring];
                    }
                    else
                    {
                        [conversationCellDataArray addObject:recentCellDataStoring];
                    }
                }
            }
        }
        else if (_recentsDataSourceMode == RecentsDataSourceModeRooms)
        {
            for (int index = 0; index < count; index++)
            {
                id<MXKRecentCellDataStoring> recentCellDataStoring = [recentsDataSource cellDataAtIndex:index];
                MXRoom* room = recentCellDataStoring.roomSummary.room;
                
                // Keep only the invites and the rooms without tag
                if (room.state.membership == MXMembershipInvite)
                {
                    [invitesCellDataArray addObject:recentCellDataStoring];
                }
                else if (!room.accountData.tags.count)
                {
                    [conversationCellDataArray addObject:recentCellDataStoring];
                }
            }
        }
        
        if (invitesCellDataArray.count > 0)
        {
            invitesSection = sectionsCount++;
        }
        
        if (favoriteCellDataArray.count > 0)
        {
            // Sort them according to their tag order
            [favoriteCellDataArray sortUsingComparator:^NSComparisonResult(id<MXKRecentCellDataStoring> recentCellData1, id<MXKRecentCellDataStoring> recentCellData2) {
                
                return [session compareRoomsByTag:kMXRoomTagFavourite room1:recentCellData1.roomSummary.room room2:recentCellData2.roomSummary.room];
                
            }];
            favoritesSection = sectionsCount++;
        }
        
        if (conversationCellDataArray.count > 0)
        {
            conversationSection = sectionsCount++;

            if (_recentsDataSourceMode == RecentsDataSourceModeRooms)
            {
                // Add the directory section after "ROOMS"
                directorySection = sectionsCount++;

                // Make _publicRoomsDirectoryDataSource start loading data
                _publicRoomsDirectoryDataSource.searchPattern = nil;
            }
        }
        
        if (lowPriorityCellDataArray.count > 0)
        {
            // Sort them according to their tag order
            [lowPriorityCellDataArray sortUsingComparator:^NSComparisonResult(id<MXKRecentCellDataStoring> recentCellData1, id<MXKRecentCellDataStoring> recentCellData2) {
                
                return [session compareRoomsByTag:kMXRoomTagLowPriority room1:recentCellData1.roomSummary.room room2:recentCellData2.roomSummary.room];
                
            }];
            lowPrioritySection = sectionsCount++;
        }
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

#pragma mark - Drag & Drop handling

- (BOOL)isMovingCellSection:(NSInteger)section
{
    return self.droppingCellIndexPath && (self.droppingCellIndexPath.section == section);
}

- (BOOL)isHiddenCellSection:(NSInteger)section
{
    return self.hiddenCellIndexPath && (self.hiddenCellIndexPath.section == section);
}

#pragma mark - Action

- (IBAction)onButtonPressed:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *shrinkButton = (UIButton*)sender;
        NSInteger selectedSectionBit = shrinkButton.tag;
        
        if (shrinkedSectionsBitMask & selectedSectionBit)
        {
            // Disclose the section
            shrinkedSectionsBitMask &= ~selectedSectionBit;
        }
        else
        {
            // Shrink this section
            shrinkedSectionsBitMask |= selectedSectionBit;
        }
        
        // Inform the delegate about the update
        [self.delegate dataSource:self didCellChange:nil];
    }
}

- (IBAction)onPublicRoomsSearchPatternUpdate:(id)sender
{
    if (publicRoomsTriggerTimer)
    {
        NSString *searchPattern = publicRoomsTriggerTimer.userInfo;

        [publicRoomsTriggerTimer invalidate];
        publicRoomsTriggerTimer = nil;

        _publicRoomsDirectoryDataSource.searchPattern = searchPattern;
    }
}

#pragma mark - Override MXKDataSource

- (void)destroy
{
    [super destroy];

    [publicRoomsTriggerTimer invalidate];
    publicRoomsTriggerTimer = nil;
}

#pragma mark - Override MXKRecentsDataSource

- (void)searchWithPatterns:(NSArray *)patternsList
{
    [super searchWithPatterns:patternsList];

    if (_publicRoomsDirectoryDataSource)
    {
        NSString *searchPattern = [patternsList componentsJoinedByString:@" "];

        // Do not send a /publicRooms request for every keystroke
        // Let user finish typing
        [publicRoomsTriggerTimer invalidate];
        publicRoomsTriggerTimer = [NSTimer scheduledTimerWithTimeInterval:0.7 target:self selector:@selector(onPublicRoomsSearchPatternUpdate:) userInfo:searchPattern repeats:NO];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Invited rooms are not editable.
    return (indexPath.section != invitesSection);
}

#pragma mark - drag and drop managemenent

- (BOOL)isDraggableCellAt:(NSIndexPath*)path
{
    if (_recentsDataSourceMode == RecentsDataSourceModePeople || _recentsDataSourceMode == RecentsDataSourceModeRooms)
    {
        return NO;
    }
    
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
    NSLog(@"[RecentsDataSource] moveCellFrom (%tu, %tu) to (%tu, %tu)", oldPath.section, oldPath.row, newPath.section, newPath.row);
    
    if ([self canCellMoveFrom:oldPath to:newPath] && ![newPath isEqual:oldPath])
    {
        NSString* oldRoomTag = [self roomTagAt:oldPath];
        NSString* dstRoomTag = [self roomTagAt:newPath];
        NSUInteger oldPos = (oldPath.section == newPath.section) ? oldPath.row : NSNotFound;
        
        NSString* tagOrder = [room.mxSession tagOrderToBeAtIndex:newPath.row from:oldPos withTag:dstRoomTag];
        
        NSLog(@"[RecentsDataSource] Update the room %@ [%@] tag from %@ to %@ with tag order %@", room.state.roomId, room.riotDisplayname, oldRoomTag, dstRoomTag, tagOrder);
        
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
                     
                     NSLog(@"[RecentsDataSource] Failed to update the tag %@ of room (%@)", dstRoomTag, room.state.roomId);
                     
                     if (moveFailure)
                     {
                         moveFailure(error);
                     }
                     
                     [self forceRefresh];
                     
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
        
        [self forceRefresh];
    }
}

@end
