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

#import "MXKDataSource.h"
#import "MXKGroupCellData.h"

/**
 Identifier to use for cells that display a group.
 */
extern NSString *const kMXKGroupCellIdentifier;

/**
 'MXKSessionGroupsDataSource' is a base class to handle the groups of a matrix session.
 A 'MXKSessionGroupsDataSource' instance provides the data source for `MXKGroupListViewController`.
 
 A section is created to handle the invitations to a group, the first one if any.
 */
@interface MXKSessionGroupsDataSource : MXKDataSource <UITableViewDataSource>
{    
@protected
    
    /**
     The current list of the group invitations (sorted in the alphabetic order).
     This list takes into account potential filter defined by`patternsList`.
     */
    NSMutableArray<MXKGroupCellData*> *groupsInviteCellDataArray;
    
    /**
     The current displayed list of the joined groups (sorted in the alphabetic order).
     This list takes into account potential filter defined by`patternsList`.
     */
    NSMutableArray<MXKGroupCellData*> *groupsCellDataArray;
}

@property (nonatomic) NSInteger groupInvitesSection;
@property (nonatomic) NSInteger joinedGroupsSection;

#pragma mark - Life cycle

/**
 Refresh all the groups summary.
 The group data are not synced with the server, use this method to refresh them according to your needs.
 
 @param completion the block to execute when a request has been done for each group (whatever the result of the requests).
 You may specify nil for this parameter.
 */
- (void)refreshGroupsSummary:(void (^)(void))completion;

/**
 Filter the current groups list according to the provided patterns.
 When patterns are not empty, the search result is stored in `filteredGroupsCellDataArray`,
 this array provides then data for the cells served by `MXKSessionGroupsDataSource`.
 
 @param patternsList the list of patterns (`NSString` instances) to match with. Set nil to cancel search.
 */
- (void)searchWithPatterns:(NSArray*)patternsList;

/**
 Get the data for the cell at the given index path.
 
 @param indexPath the index of the cell in the table
 @return the cell data
 */
- (id<MXKGroupCellDataStoring>)cellDataAtIndex:(NSIndexPath*)indexPath;

/**
 Get the index path of the cell related to the provided groupId.
 
 @param groupId the group identifier.
 @return indexPath the index of the cell (nil if not found).
 */
- (NSIndexPath*)cellIndexPathWithGroupId:(NSString*)groupId;

/**
 Leave the group displayed at the provided path.
 
 @param indexPath the index of the group cell in the table
 */
- (void)leaveGroupAtIndexPath:(NSIndexPath *)indexPath;

@end
