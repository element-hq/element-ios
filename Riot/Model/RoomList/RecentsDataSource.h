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

#import <MatrixKit/MatrixKit.h>

@class PublicRoomsDirectoryDataSource;

/**
 'RecentsDataSource' class inherits from 'MXKInterleavedRecentsDataSource' to define Riot recents source.
 */
@interface RecentsDataSource : MXKInterleavedRecentsDataSource

/**
 Return the header height from the section.
 */
- (CGFloat)heightForHeaderInSection:(NSInteger)section;

#pragma mark - Directory handling
/**
 The data source used to manage search in public rooms.
 */
@property (nonatomic, readonly) PublicRoomsDirectoryDataSource *publicRoomsDirectoryDataSource;

/**
 Hide the public rooms directory cell. YES by default.
 */
@property (nonatomic) BOOL hidePublicRoomsDirectory;

/**
 Hide recents. NO by default.
 */
@property (nonatomic) BOOL hideRecents;

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
