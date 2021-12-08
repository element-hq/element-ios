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

#import "MXKDataSource.h"
#import "MXKSearchCellDataStoring.h"

#import "MXKEventFormatter.h"

/**
 String identifying the object used to store and prepare the cell data of a result during a message search.
 */
extern NSString *const kMXKSearchCellDataIdentifier;

/**
 The data source for `MXKSearchViewController` in case of message search.
 
 Use the `initWithMatrixSession:` constructor to search in all user's rooms.
 Use the `initWithRoomId:andMatrixSession: constructor to search in a specific room.
 */
@interface MXKSearchDataSource : MXKDataSource <UITableViewDataSource>
{
    @protected
    /**
     List of results retrieved from the server.
     The` MXKSearchDataSource` class stores MXKSearchCellDataStoring objects in it.
     */
    NSMutableArray<MXKCellData*> *cellDataArray;
}

/**
 The current search.
 */
@property (nonatomic, readonly) NSString *searchText;

/**
 The room events filter which is applied during the messages search.
 */
@property (nonatomic) MXRoomEventFilter *roomEventFilter;

/**
 Total number of results available on the server.
 */
@property (nonatomic, readonly) NSUInteger serverCount;

/**
 The events to display texts formatter.
 `MXKCellData` instances can use it to format text.
 */
@property (nonatomic) MXKEventFormatter *eventFormatter;

/**
 Flag indicating if there are still results (in the past) to get with paginateBack.
 */
@property (nonatomic, readonly) BOOL canPaginate;

/**
 Tell whether the room display name should be displayed in each result cell. NO by default.
 */
@property (nonatomic) BOOL shouldShowRoomDisplayName;


/**
 Launch a message search homeserver side.

 @discussion The result depends on the 'roomEventFilter' propertie.
 
 @param textPattern the text to search in messages data.
 @param force tell whether the search must be launched even if the text pattern is unchanged.
 */
- (void)searchMessages:(NSString*)textPattern force:(BOOL)force;

/**
 Load more results from the past.
 */
- (void)paginateBack;

/**
 Get the data for the cell at the given index.

 @param index the index of the cell in the array
 @return the cell data
 */
- (MXKCellData*)cellDataAtIndex:(NSInteger)index;

/**
 Convert the results of a homeserver search requests into cells.
 
 This methods is in charge of filling `cellDataArray`.
 
 @param roomEventResults the homeserver response as provided by MatrixSDK.
 @param onComplete the block called once complete.
 */
- (void)convertHomeserverResultsIntoCells:(MXSearchRoomEventResults*)roomEventResults onComplete:(dispatch_block_t)onComplete;

@end
