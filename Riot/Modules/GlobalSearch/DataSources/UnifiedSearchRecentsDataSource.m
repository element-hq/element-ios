/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "UnifiedSearchRecentsDataSource.h"

#import "ThemeService.h"

#import "RoomIdOrAliasTableViewCell.h"
#import "DirectoryRecentTableViewCell.h"

#import "MXRoom+Riot.h"
#import "GeneratedInterface-Swift.h"

@interface UnifiedSearchRecentsDataSource()
{
    // The potential room id or alias typed in search input.
    NSString *roomIdOrAlias;
}
@end

@implementation UnifiedSearchRecentsDataSource

- (instancetype)initWithMatrixSession:(MXSession *)mxSession recentsListService:(id<RecentsListServiceProtocol>)recentsListService
{
    self = [super initWithMatrixSession:mxSession recentsListService:recentsListService];
    if (self)
    {
        _hideRecents = NO;
    }
    return self;
}

#pragma mark - Sections

- (RecentsDataSourceSections *)makeDataSourceSections
{
    NSMutableArray *types = [NSMutableArray array];
    if (roomIdOrAlias.length)
    {
        // The current search pattern corresponds to a valid room id or room alias
        [types addObject:@(RecentsDataSourceSectionTypeSearchedRoom)];
    }
    
    // The public rooms directory cell is then visible whatever the search activity.
    if (RiotSettings.shared.unifiedSearchScreenShowPublicDirectory)
    {
        [types addObject:@(RecentsDataSourceSectionTypeDirectory)];
    }
    
    if (!_hideRecents) {
        NSArray *existingTypes = [[super makeDataSourceSections] sectionTypes];
        [types addObjectsFromArray:existingTypes];
    }
    
    return [[RecentsDataSourceSections alloc] initWithSectionTypes:types.copy];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count = 0;

    RecentsDataSourceSectionType sectionType = [self.sections sectionTypeForSectionIndex:section];
    if (sectionType == RecentsDataSourceSectionTypeSearchedRoom)
    {
        count = 1;
    }
    else if (sectionType == RecentsDataSourceSectionTypeDirectory)
    {
        count = 1;
    }
    else
    {
        count = [super tableView:tableView numberOfRowsInSection:section];
    }
    
    return count;
}

- (UIView *)viewForHeaderInSection:(NSInteger)section withFrame:(CGRect)frame inTableView:(UITableView*)tableView
{
    UIView *sectionHeader = nil;
    
    if ([self.sections sectionTypeForSectionIndex:section] != RecentsDataSourceSectionTypeSearchedRoom)
    {
        sectionHeader = [super viewForHeaderInSection:section withFrame:frame inTableView:tableView];
    }
    
    return sectionHeader;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RecentsDataSourceSectionType sectionType = [self.sections sectionTypeForSectionIndex:indexPath.section];
    if (sectionType == RecentsDataSourceSectionTypeSearchedRoom)
    {
        RoomIdOrAliasTableViewCell *roomIdOrAliasCell = [tableView dequeueReusableCellWithIdentifier:RoomIdOrAliasTableViewCell.defaultReuseIdentifier];
        if (!roomIdOrAliasCell)
        {
            roomIdOrAliasCell = [[RoomIdOrAliasTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[RoomIdOrAliasTableViewCell defaultReuseIdentifier]];
        }
        
        [roomIdOrAliasCell render:roomIdOrAlias];
        
        return roomIdOrAliasCell;
    }
    else if (sectionType == RecentsDataSourceSectionTypeDirectory)
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
    RecentsDataSourceSectionType sessionType = [self.sections sectionTypeForSectionIndex:indexPath.section];
    if (sessionType == RecentsDataSourceSectionTypeSearchedRoom)
    {
        return RoomIdOrAliasTableViewCell.cellHeight;
    }
    
    if (sessionType == RecentsDataSourceSectionTypeDirectory)
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
