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

#import "EventFormatter.h"

#import "RiotDesignValues.h"

#import "RoomIdOrAliasTableViewCell.h"
#import "DirectoryRecentTableViewCell.h"

#import "PublicRoomsDirectoryDataSource.h"

#import "MXRoom+Riot.h"

#import "RecentCellData.h"

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

    NSInteger searchedRoomIdOrAliasSection; // used to display the potential room id or alias typed during search.
    NSInteger directorySection;
    NSInteger invitesSection;
    NSInteger favoritesSection;
    NSInteger conversationSection;
    NSInteger lowPrioritySection;
    NSInteger sectionsCount;
    
    NSInteger shrinkedSectionsBitMask;
    
    NSMutableDictionary<NSString*, id> *roomTagsListenerByUserId;
    
    // The potential room id or alias typed in search input.
    NSString *roomIdOrAlias;

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
        favoriteCellDataArray = [[NSMutableArray alloc] init];
        conversationCellDataArray = [[NSMutableArray alloc] init];
        lowPriorityCellDataArray = [[NSMutableArray alloc] init];

        searchedRoomIdOrAliasSection = -1;
        directorySection = -1;
        invitesSection = -1;
        favoritesSection = -1;
        conversationSection = -1;
        lowPrioritySection = -1;
        sectionsCount = 0;
        
        _hideRecents = NO;
        _hidePublicRoomsDirectory = YES;
        
        shrinkedSectionsBitMask = 0;
        
        roomTagsListenerByUserId = [[NSMutableDictionary alloc] init];
        
        // Set default data and view classes
        [self registerCellDataClass:RecentCellData.class forCellIdentifier:kMXKRecentCellIdentifier];
    }
    return self;
}


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
        [self refreshRoomsSectionsAndReload];
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

                                                                            [self refreshRoomsSectionsAndReload];

                                                                        });
                                                                    }

                                                                }];

            [roomTagsListenerByUserId setObject:roomTagsListener forKey:dataSource.mxSession.myUser.userId];
        }
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
    if ([self.mxSessions indexOfObject:mxSession] != NSNotFound)
    {
        [self refreshRoomsSectionsAndReload];
    }
}

#pragma mark - 

- (void)setHidePublicRoomsDirectory:(BOOL)hidePublicRoomsDirectory
{
    if (_hidePublicRoomsDirectory != hidePublicRoomsDirectory)
    {
        _hidePublicRoomsDirectory = hidePublicRoomsDirectory;
        
        if (!_hidePublicRoomsDirectory)
        {
            // Start by looking for all public rooms
            self.publicRoomsDirectoryDataSource.searchPattern = nil;
        }
        
        [self refreshRoomsSectionsAndReload];
    }
}

- (void)setHideRecents:(BOOL)hideRecents
{
    if (_hideRecents != hideRecents)
    {
        _hideRecents = hideRecents;
        
        [self refreshRoomsSectionsAndReload];
    }
}

#pragma mark - UITableViewDataSource

/**
 Return the header height from the section.
 */
- (CGFloat)heightForHeaderInSection:(NSInteger)section
{
    if ((section == directorySection) || (section == invitesSection) || (section == favoritesSection) || (section == conversationSection) || (section == lowPrioritySection))
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

    if (section == searchedRoomIdOrAliasSection)
    {
        count = 1;
    }
    else if (section == directorySection)
    {
        count = 1;
    }
    else if (section == favoritesSection && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_FAVORITES))
    {
        count = favoriteCellDataArray.count;
    }
    else if (section == conversationSection && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_CONVERSATIONS))
    {
        count = conversationCellDataArray.count;
    }
    else if (section == lowPrioritySection && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_LOWPRIORITY))
    {
        count = lowPriorityCellDataArray.count;
    }
    else if (section == invitesSection && !(shrinkedSectionsBitMask & RECENTSDATASOURCE_SECTION_INVITES))
    {
        count = invitesCellDataArray.count;
    }
    
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
    
    if (section < sectionsCount && section != searchedRoomIdOrAliasSection)
    {
        NSString* sectionTitle = @"";
        NSInteger sectionBitwise = 0;
        UIImageView *chevronView;
        
        if (section == directorySection)
        {
            sectionTitle = NSLocalizedStringFromTable(@"room_recents_directory", @"Vector", nil);
        }
        else if (section == favoritesSection)
        {
            sectionTitle = NSLocalizedStringFromTable(@"room_recents_favourites", @"Vector", nil);
            sectionBitwise = RECENTSDATASOURCE_SECTION_FAVORITES;
        }
        else if (section == conversationSection)
        {
            sectionTitle = NSLocalizedStringFromTable(@"room_recents_conversations", @"Vector", nil);
            sectionBitwise = RECENTSDATASOURCE_SECTION_CONVERSATIONS;
        }
        else if (section == lowPrioritySection)
        {
            sectionTitle = NSLocalizedStringFromTable(@"room_recents_low_priority", @"Vector", nil);
            sectionBitwise = RECENTSDATASOURCE_SECTION_LOWPRIORITY;
        }
        else if (section == invitesSection)
        {
            sectionTitle = NSLocalizedStringFromTable(@"room_recents_invites", @"Vector", nil);
            sectionBitwise = RECENTSDATASOURCE_SECTION_INVITES;
        }
        
        sectionHeader = [[UIView alloc] initWithFrame:frame];
        sectionHeader.backgroundColor = kRiotColorLightGrey;
        
        if (sectionBitwise)
        {
            // Add shrink button
            UIButton *shrinkButton = [UIButton buttonWithType:UIButtonTypeCustom];
            CGRect frame = sectionHeader.frame;
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
    if (indexPath.section == searchedRoomIdOrAliasSection)
    {
        RoomIdOrAliasTableViewCell *roomIdOrAliasCell = [tableView dequeueReusableCellWithIdentifier:RoomIdOrAliasTableViewCell.defaultReuseIdentifier];
        if (!roomIdOrAliasCell)
        {
            roomIdOrAliasCell = [[RoomIdOrAliasTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[RoomIdOrAliasTableViewCell defaultReuseIdentifier]];
        }
        
        [roomIdOrAliasCell render:roomIdOrAlias];
        
        return roomIdOrAliasCell;
    }
    else if (indexPath.section == directorySection)
    {
        // For the cell showing the public rooms directory search result,
        // skip the MatrixKit mechanism and return directly the UITableViewCell
        DirectoryRecentTableViewCell *directoryCell = [tableView dequeueReusableCellWithIdentifier:DirectoryRecentTableViewCell.defaultReuseIdentifier];
        if (!directoryCell)
        {
            directoryCell = [[DirectoryRecentTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[DirectoryRecentTableViewCell defaultReuseIdentifier]];
        }

        [directoryCell render:_publicRoomsDirectoryDataSource];

        return directoryCell;
    }

    if (self.droppingCellIndexPath && [indexPath isEqual:self.droppingCellIndexPath])
    {
        static NSString* cellIdentifier = @"VectorRecentsMovingCell";
        
        UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"VectorRecentsMovingCell"];
        
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
    if (indexPath.section == searchedRoomIdOrAliasSection)
    {
        return RoomIdOrAliasTableViewCell.cellHeight;
    }
    
    if (indexPath.section == directorySection)
    {
        // For the cell showing the public rooms directory search result,
        // skip the MatrixKit mechanism and return directly the cell height
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
    
    searchedRoomIdOrAliasSection = directorySection = favoritesSection = conversationSection = lowPrioritySection = invitesSection = -1;
    sectionsCount = 0;
    
    if (roomIdOrAlias.length)
    {
        // The current search pattern corresponds to a valid room id or room alias
        searchedRoomIdOrAliasSection = sectionsCount++;
    }
    
    if (!_hidePublicRoomsDirectory)
    {
        // The public rooms directory cell is then visible whatever the search activity.
        directorySection = sectionsCount++;
    }

    if (!_hideRecents && displayedRecentsDataSourceArray.count > 0)
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
            MXRoom* room = recentCellDataStoring.roomSummary.room;

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

        [invitesCellDataArray removeObject:[NSNull null]];
        if (invitesCellDataArray.count > 0)
        {
            invitesSection = sectionsCount++;
        }
        
        [favoriteCellDataArray removeObject:[NSNull null]];
        if (favoriteCellDataArray.count > 0)
        {
            favoritesSection = sectionsCount++;
        }
        
        [conversationCellDataArray removeObject:[NSNull null]];
        if (conversationCellDataArray.count > 0)
        {
            conversationSection = sectionsCount++;
        }
        
        [lowPriorityCellDataArray removeObject:[NSNull null]];
        if (lowPriorityCellDataArray.count > 0)
        {
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
    // Check whether the typed input is a room alias or a room identifier.
    roomIdOrAlias = nil;
    if (patternsList.count == 1)
    {
        NSString *pattern = patternsList[0];
        
        if ([MXTools isMatrixRoomAlias:pattern] || [MXTools isMatrixRoomIdentifier:pattern])
        {
            // Display this room id/alias only if it is not already joined by the user
            MXKAccountManager *accountManager = [MXKAccountManager sharedManager];
            if (![accountManager accountKnowingRoomWithRoomIdOrAlias:pattern])
            {
                roomIdOrAlias = pattern;
            }
        }
    }
    
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
    MXRoom* room = [self getRoomAtIndexPath:indexPath];
    if (room)
    {
        NSArray* invitedRooms = room.mxSession.invitedRooms;
        
        // Display no action for the invited room
        if (invitedRooms && ([invitedRooms indexOfObject:room] != NSNotFound))
        {
            return NO;
        }
    }
    
    return YES;
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
