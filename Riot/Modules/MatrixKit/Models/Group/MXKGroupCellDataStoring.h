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

#import <MatrixSDK/MatrixSDK.h>

#import "MXKCellData.h"

@class MXKSessionGroupsDataSource;

/**
 `MXKGroupCellDataStoring` defines a protocol a class must conform in order to store group cell data
 managed by `MXKSessionGroupsDataSource`.
 */
@protocol MXKGroupCellDataStoring <NSObject>

@property (nonatomic, weak, readonly) MXKSessionGroupsDataSource *groupsDataSource;

@property (nonatomic, readonly) MXGroup *group;

@property (nonatomic, readonly) NSString *groupDisplayname;
@property (nonatomic, readonly) NSString *sortingDisplayname;

#pragma mark - Public methods
/**
 Create a new `MXKCellData` object for a new group cell.

 @param group the `MXGroup` object that has data about the group.
 @param groupsDataSource the `MXKSessionGroupsDataSource` object that will use this instance.
 @return the newly created instance.
 */
- (instancetype)initWithGroup:(MXGroup*)group andGroupsDataSource:(MXKSessionGroupsDataSource*)groupsDataSource;

/**
 The `MXKSessionGroupsDataSource` object calls this method when the group data has been updated.
 
 @param group the updated group.
 */
- (void)updateWithGroup:(MXGroup*)group;

@end
