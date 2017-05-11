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

#import <MatrixKit/MatrixKit.h>

#import "PublicRoomsDirectoryDataSource.h"

/**
 List the different modes used to prepare the recents data source.
 Each mode corresponds to an application tab: Home, Favourites, People and Rooms.
 */
typedef enum : NSUInteger
{
    RecentsDataSourceModeHome,
    RecentsDataSourceModeFavourites,
    RecentsDataSourceModePeople,
    RecentsDataSourceModeRooms
    
} RecentsDataSourceMode;


/**
 Action identifier used when the user tapped on the directory change button.

 The `userInfo` is nil.
 */
extern NSString *const kRecentsDataSourceTapOnDirectoryServerChange;

/**
 'RecentsDataSource' class inherits from 'MXKInterleavedRecentsDataSource' to define the Riot recents source
 shared between all the applications tabs.
 */
@interface RecentsDataSource : MXKInterleavedRecentsDataSource

@property (nonatomic) NSInteger directorySection;
@property (nonatomic) NSInteger invitesSection;
@property (nonatomic) NSInteger favoritesSection;
@property (nonatomic) NSInteger peopleSection;
@property (nonatomic) NSInteger conversationSection;
@property (nonatomic) NSInteger lowPrioritySection;

@property (nonatomic, readonly) NSArray* invitesCellDataArray;
@property (nonatomic, readonly) NSArray* favoriteCellDataArray;
@property (nonatomic, readonly) NSArray* peopleCellDataArray;
@property (nonatomic, readonly) NSArray* conversationCellDataArray;
@property (nonatomic, readonly) NSArray* lowPriorityCellDataArray;

/**
 Set the delegate by specifying the selected display mode.
 */
- (void)setDelegate:(id<MXKDataSourceDelegate>)delegate andRecentsDataSourceMode:(RecentsDataSourceMode)recentsDataSourceMode;

/**
 The current mode (RecentsDataSourceModeHome by default).
 */
@property (nonatomic, readonly) RecentsDataSourceMode recentsDataSourceMode;

/**
 The data source used to manage the rooms from directory.
 */
@property (nonatomic) PublicRoomsDirectoryDataSource *publicRoomsDirectoryDataSource;

/**
 Refresh the recents data source and notify its delegate.
 */
- (void)forceRefresh;

/**
 Tell whether the sections are shrinkable. NO by default.
 */
@property (nonatomic) BOOL areSectionsShrinkable;

/**
 Get the sticky header view for the specified section.
 
 @param section the section  index
 @param frame the drawing area for the header of the specified section.
 @return the sticky header view.
 */
- (UIView *)viewForStickyHeaderInSection:(NSInteger)section withFrame:(CGRect)frame;

/**
 Get the height of the section header view.

 @param section the section  index
 @return the header height.
 */
- (CGFloat)heightForHeaderInSection:(NSInteger)section;

#pragma mark - Drag & Drop handling
/**
 Return true of the cell can be moved from a section to another one.
 */
- (BOOL)isDraggableCellAt:(NSIndexPath*)path;

/**
 Return true of the cell can be moved from a section to another one.
 */
- (BOOL)canCellMoveFrom:(NSIndexPath*)oldPath to:(NSIndexPath*)newPath;

/**
 There is a pending drag and drop cell.
 It defines its path of the source cell.
 */
@property (nonatomic) NSIndexPath* hiddenCellIndexPath;

/**
 There is a pending drag and drop cell.
 It defines its path of the destination cell.
 */
@property (nonatomic) NSIndexPath* droppingCellIndexPath;

/**
 The movingCellBackgroundImage.
 */
@property (nonatomic) UIImageView* droppingCellBackGroundView;

/**
 Move a cell from a path to another one.
 It is based on room Tag.
 */
- (void)moveRoomCell:(MXRoom*)room from:(NSIndexPath*)oldPath to:(NSIndexPath*)newPath success:(void (^)())moveSuccess failure:(void (^)(NSError *error))moveFailure;

/**
 The current number of the favourite rooms with missed notifications.
 */
@property (nonatomic, readonly) NSUInteger missedFavouriteDiscussionsCount;

/**
 The current number of the favourite rooms with unread highlighted messages.
 */
@property (nonatomic, readonly) NSUInteger missedHighlightFavouriteDiscussionsCount;

/**
 The current number of the direct chats with missed notifications, including the invites.
 */
@property (nonatomic, readonly) NSUInteger missedDirectDiscussionsCount;

/**
 The current number of the direct chats with unread highlighted messages.
 */
@property (nonatomic, readonly) NSUInteger missedHighlightDirectDiscussionsCount;

/**
 The current number of the group chats with missed notifications, including the invites.
 */
@property (nonatomic, readonly) NSUInteger missedGroupDiscussionsCount;

/**
 The current number of the group chats with unread highlighted messages.
 */
@property (nonatomic, readonly) NSUInteger missedHighlightGroupDiscussionsCount;

@end
