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
 'RecentsDataSource' class inherits from 'MXKInterleavedRecentsDataSource' to define the Riot recents source
 shared between all the applications tabs.
 */
@interface RecentsDataSource : MXKInterleavedRecentsDataSource
{
@protected
    NSInteger directorySection;
    NSInteger invitesSection;
    NSInteger favoritesSection;
    NSInteger conversationSection;
    NSInteger lowPrioritySection;
    
    NSInteger sectionsCount;
}

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

@end
