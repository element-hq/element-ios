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

#import <UIKit/UIKit.h>
#import <MatrixSDK/MatrixSDK.h>

#import "MXKDataSource.h"
#import "MXKRoomMemberCellData.h"

#import "MXKAppSettings.h"

/**
 Identifier to use for cells that display a room member.
 */
extern NSString *const kMXKRoomMemberCellIdentifier;

/**
 The data source for `MXKRoomMemberListViewController`.
 */
@interface MXKRoomMemberListDataSource : MXKDataSource <UITableViewDataSource> {

@protected

    /**
     The data for the cells served by `MXKRoomMembersDataSource`.
     */
    NSMutableArray *cellDataArray;
    
    /**
     The filtered members: sub-list of `cellDataArray` defined by `searchWithPatterns:`.
     */
    NSMutableArray *filteredCellDataArray;
}

/**
 The id of the room managed by the data source.
 */
@property (nonatomic, readonly) NSString *roomId;

/**
 The settings used to sort/display room members.
 
 By default the shared application settings are considered.
 */
@property (nonatomic) MXKAppSettings *settings;


#pragma mark - Life cycle

/**
 Initialise the data source to serve members corresponding to the passed room.
 
 @param roomId the id of the room to get members from.
 @param mxSession the Matrix session to get data from.
 @return the newly created instance.
 */
- (instancetype)initWithRoomId:(NSString*)roomId andMatrixSession:(MXSession*)mxSession;

/**
 Filter the current members list according to the provided patterns.
 When patterns are not empty, the search result is stored in `filteredCellDataArray`,
 this array provides then data for the cells served by `MXKRoomMembersDataSource`.
 
 @param patternsList the list of patterns (`NSString` instances) to match with. Set nil to cancel search.
 */
- (void)searchWithPatterns:(NSArray*)patternsList;

/**
 Get the data for the cell at the given index.

 @param index the index of the cell in the array
 @return the cell data
 */
- (id<MXKRoomMemberCellDataStoring>)cellDataAtIndex:(NSInteger)index;

/**
 Get height of the celle at the given index.

 @param index the index of the cell in the array
 @return the cell height
 */
- (CGFloat)cellHeightAtIndex:(NSInteger)index;

@end
