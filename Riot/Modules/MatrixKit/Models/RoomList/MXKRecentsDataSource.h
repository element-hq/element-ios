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

#import "MXKSessionRecentsDataSource.h"

/**
 'MXKRecentsDataSource' is a base class to handle recents from one or multiple matrix sessions.
 A 'MXKRecentsDataSource' instance provides the recents data source for `MXKRecentListViewController`.
 
 By default, the recents list of different sessions are handled into separate sections.
 */
@interface MXKRecentsDataSource : MXKDataSource <UITableViewDataSource, MXKDataSourceDelegate>
{
@protected
    /**
     Array of `MXKSessionRecentsDataSource` instances. Only ready and non empty data source are listed here.
     (Note: a data source may be considered as empty during searching)
     */
    NSMutableArray *displayedRecentsDataSourceArray;
    
    /**
     Array of shrinked sources. Sub-list of displayedRecentsDataSourceArray.
     */
    NSMutableArray *shrinkedRecentsDataSourceArray;
}

/**
 List of associated matrix sessions.
 */
@property (nonatomic, readonly) NSArray* mxSessions;

/**
 The number of available recents data sources (This count may be different than mxSession.count because empty data sources are ignored).
 */
@property (nonatomic, readonly) NSUInteger displayedRecentsDataSourcesCount;

/**
 Tell whether there are some unread messages.
 */
@property (nonatomic, readonly) BOOL hasUnread;

/**
 The current search patterns list.
 */
@property (nonatomic, readonly) NSArray* searchPatternsList;

@property (nonatomic, strong) MXSpace *currentSpace;

#pragma mark - Configuration

/**
 Add recents data from a matrix session.
 
 @param mxSession the Matrix session to retrieve contextual data.
 @return the new 'MXKSessionRecentsDataSource' instance created for this Matrix session.
 */
- (MXKSessionRecentsDataSource *)addMatrixSession:(MXSession*)mxSession;

/**
 Remove recents data related to a matrix session.
 
 @param mxSession the session to remove.
 */
- (void)removeMatrixSession:(MXSession*)mxSession;

/**
 Filter the current recents list according to the provided patterns.
 
 @param patternsList the list of patterns (`NSString` instances) to match with. Set nil to cancel search.
 */
- (void)searchWithPatterns:(NSArray*)patternsList;

/**
 Get the section header view.
 
 @param section the section  index
 @param frame the drawing area for the header of the specified section.
 @param tableView the table view
 @return the section header.
 */
- (UIView *)viewForHeaderInSection:(NSInteger)section withFrame:(CGRect)frame inTableView:(UITableView*)tableView;

/**
 Get the data for the cell at the given index path.

 @param indexPath the index of the cell
 @return the cell data
 */
- (id<MXKRecentCellDataStoring>)cellDataAtIndexPath:(NSIndexPath*)indexPath;

/**
 Get the height of the cell at the given index path.

 @param indexPath the index of the cell
 @return the cell height
 */
- (CGFloat)cellHeightAtIndexPath:(NSIndexPath*)indexPath;

/**
 Get the index path of the cell related to the provided roomId and session.
 
 @param roomId the room identifier.
 @param mxSession the matrix session in which the room should be available.
 @return indexPath the index of the cell (nil if not found or if the related section is shrinked).
 */
- (NSIndexPath*)cellIndexPathWithRoomId:(NSString*)roomId andMatrixSession:(MXSession*)mxSession;

/**
 Returns the room at the index path
 
 @param indexPath the index of the cell
 @return the MXRoom if it exists
 */
- (MXRoom*)getRoomAtIndexPath:(NSIndexPath *)indexPath;

/**
 Leave the room at the index path

 @param indexPath the index of the cell
 */
- (void)leaveRoomAtIndexPath:(NSIndexPath *)indexPath;

/**
 Action registered on buttons used to shrink/disclose recents sources.
 */
- (IBAction)onButtonPressed:(id)sender;

@end
