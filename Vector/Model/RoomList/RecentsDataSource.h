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

/**
 'RecentsDataSource' class inherits from 'MXKInterleavedRecentsDataSource' to define Vector recents source.
 */
@interface RecentsDataSource : MXKInterleavedRecentsDataSource

/**
 The callback when a room invitation is rejected.
 */
@property (nonatomic, copy) void (^onRoomInvitationReject)(MXRoom*);

/**
 The callback when a room invitation is accepted.
 */
@property (nonatomic, copy) void (^onRoomInvitationAccept)(MXRoom*);

/**
 There is a pending drag and drop cell.
 It defines its path.
 */
@property (nonatomic, copy) NSIndexPath* movingCellIndexPath;

/**
 The movingCellBackgroundImage;
 */
@property (nonatomic) UIImageView* movingCellBackGroundView;

/**
 Return the header height from the section.
 */
- (CGFloat)heightForHeaderInSection:(NSInteger)section;

/**
 Return true of the cell can be moved from a section to another one.
 */
- (BOOL)isDraggableCellAt:(NSIndexPath*)path;

/**
 Move a cell from a path to another one.
 It is based on room Tag.
 */
- (void)moveCellFrom:(NSIndexPath*)oldPath to:(NSIndexPath*)newPath success:(void (^)())moveSuccess failure:(void (^)(NSError *error))moveFailure;

@end
