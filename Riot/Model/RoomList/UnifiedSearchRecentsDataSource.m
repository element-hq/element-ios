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
    [self.publicRoomsDirectoryDataSource paginate:nil failure:nil];
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
    NSInteger sectionsCount = 0;
    
    // Check whether all data sources are ready before rendering recents
    if (self.state == MXKDataSourceStateReady)
    {
        sectionsCount = [super numberOfSectionsInTableView:tableView];
        NSInteger sectionsOffset = 0;
        
        if (roomIdOrAlias.length)
        {
            // The current search pattern corresponds to a valid room id or room alias
            searchedRoomIdOrAliasSection = sectionsOffset++;
        }
        
        // The public rooms directory cell is then visible whatever the search activity.
        self.directorySection = sectionsOffset++;
        
        if (_hideRecents)
        {
            self.invitesSection = self.favoritesSection = self.peopleSection = self.conversationSection = self.lowPrioritySection = -1;
            sectionsCount = sectionsOffset;
        }
        else
        {
            if (self.invitesSection != -1)
            {
                self.invitesSection += sectionsOffset;
            }
            if (self.favoritesSection != -1)
            {
                self.favoritesSection += sectionsOffset;
            }
            if (self.peopleSection != -1)
            {
                self.peopleSection += sectionsOffset;
            }
            if (self.conversationSection != -1)
            {
                self.conversationSection += sectionsOffset;
            }
            if (self.lowPrioritySection != -1)
            {
                self.lowPrioritySection += sectionsOffset;
            }
            sectionsCount += sectionsOffset;
        }
    }
    return sectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count = 0;

    if (section == searchedRoomIdOrAliasSection)
    {
        count = 1;
    }
    else if (section == self.directorySection)
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
        sectionHeader = [super viewForHeaderInSection:section withFrame:frame];
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
    else if (indexPath.section == self.directorySection)
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
    
    if (indexPath.section == self.directorySection)
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
