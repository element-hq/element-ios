/*
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

#import "UnifiedSearchRecentsDataSource.h"

#import "RiotDesignValues.h"

#import "RoomIdOrAliasTableViewCell.h"
#import "DirectoryRecentTableViewCell.h"

#import "MXRoom+Riot.h"

@interface UnifiedSearchRecentsDataSource()
{
    NSInteger searchedRoomIdOrAliasSection; // used to display the potential room id or alias typed during search.
    
    // The potential room id or alias typed in search input.
    NSString *roomIdOrAlias;
}
@end

@implementation UnifiedSearchRecentsDataSource

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        searchedRoomIdOrAliasSection = -1;
        
        _hideRecents = NO;
    }
    return self;
}

#pragma mark -

- (void)setPublicRoomsDirectoryDataSource:(PublicRoomsDirectoryDataSource *)publicRoomsDirectoryDataSource
{
    [super setPublicRoomsDirectoryDataSource:publicRoomsDirectoryDataSource];
    
    // Start by looking for all public rooms
    self.publicRoomsDirectoryDataSource.searchPattern = nil;
}

- (void)setHideRecents:(BOOL)hideRecents
{
    if (_hideRecents != hideRecents)
    {
        _hideRecents = hideRecents;
        
        [self forceRefresh];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Check whether all data sources are ready before rendering recents
    if (self.state == MXKDataSourceStateReady)
    {
        NSInteger sectionsOffset = 0;
        
        if (roomIdOrAlias.length)
        {
            // The current search pattern corresponds to a valid room id or room alias
            searchedRoomIdOrAliasSection = sectionsOffset++;
        }
        
        // The public rooms directory cell is then visible whatever the search activity.
        directorySection = sectionsOffset++;
        
        if (_hideRecents)
        {
            invitesSection = favoritesSection = conversationSection = lowPrioritySection = -1;
            sectionsCount = 0;
        }
        else
        {
            if (invitesSection != -1)
            {
                invitesSection += sectionsOffset;
            }
            if (favoritesSection != -1)
            {
                favoritesSection += sectionsOffset;
            }
            if (conversationSection != -1)
            {
                conversationSection += sectionsOffset;
            }
            if (lowPrioritySection != -1)
            {
                lowPrioritySection += sectionsOffset;
            }
        }
        
        sectionsCount += sectionsOffset;
        return sectionsCount;
    }
    return 0;
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
    else
    {
        count = [super tableView:tableView numberOfRowsInSection:section];
    }
    
    return count;
}

- (UIView *)viewForHeaderInSection:(NSInteger)section withFrame:(CGRect)frame
{
    UIView *sectionHeader = nil;
    
    if (section != searchedRoomIdOrAliasSection)
    {
        if (section == directorySection)
        {
            sectionHeader = [[UIView alloc] initWithFrame:frame];
            sectionHeader.backgroundColor = kRiotColorLightGrey;
            
            // Add label
            frame = sectionHeader.frame;
            frame.origin.x = 20;
            frame.origin.y = 5;
            frame.size.width = sectionHeader.frame.size.width - 10;
            frame.size.height -= 10;
            UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
            headerLabel.font = [UIFont boldSystemFontOfSize:15.0];
            headerLabel.backgroundColor = [UIColor clearColor];
            headerLabel.text = NSLocalizedStringFromTable(@"room_recents_directory", @"Vector", nil);
            [sectionHeader addSubview:headerLabel];
        }
        else
        {
            sectionHeader = [super viewForHeaderInSection:section withFrame:frame];
        }
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

        [directoryCell render:self.publicRoomsDirectoryDataSource];

        return directoryCell;
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
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

    return [super cellHeightAtIndexPath:indexPath];
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
}

@end
