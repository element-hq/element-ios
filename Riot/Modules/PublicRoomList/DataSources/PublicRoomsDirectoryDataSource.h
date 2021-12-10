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

#import <Foundation/Foundation.h>

#import "MatrixKit.h"

/**
 `PublicRoomsDirectoryDataSource` is a base class to display public rooms directory.
 A `PublicRoomsDirectoryDataSource` instance provides rooms to displayed in a`PublicRoomsDirectoryViewController`.

 As a `MXKDataSource` child class, the class has a state where values have the following meanings:
     - MXKDataSourceStatePreparing: the data source is not yet ready or it is fetching data from the homeserver.
     - MXKDataSourceStateReady: the data source data is ready.
     - MXKDataSourceStateFailed: the data source failed to fetch data.
 
 There is no way in Matrix to be notified when there is a change in the public room directory.
 As a workaround, the data source refreshes its data when there are more than 10s old.
 */
@interface PublicRoomsDirectoryDataSource : MXKDataSource <UITableViewDataSource, NSCopying>

/**
 The homeserver to list public rooms from.
 Default is nil. In this case, the user's homeserver is used.
 */
@property (nonatomic) NSString *homeserver;

/**
 Flag to indicate to list all public rooms from all networks of `homeserver`.
 NO will list only pure Matrix rooms.
 */
@property (nonatomic) BOOL includeAllNetworks;

/**
 Flag to indicate to show Not Safe For Work rooms in the public room list.
 */
@property (nonatomic) BOOL showNSFWRooms;

/**
 List public rooms from a third party protocol.
 Default is nil.
 */
@property (nonatomic) MXThirdPartyProtocolInstance *thirdpartyProtocolInstance;

/**
 The display name of the current directory server.
 */
@property (nonatomic, readonly) NSString *directoryServerDisplayname;

/**
 The number of public rooms that have been fetched so far.
 */
@property (nonatomic, readonly) NSUInteger roomsCount;

/**
 The total number of public rooms matching `searchPattern`.
 It is accurate only if 'searchResultsCountIsLimited' is NO.
 */
@property (nonatomic, readonly) NSUInteger searchResultsCount;

/**
 In case of search with a lot of matching public rooms, we cannot return an accurate
 value except by paginating the full list of rooms, which is not expected.

 This flag indicates that we know that there is more matching rooms than we got
 so far.
 */
@property (nonatomic, readonly) BOOL searchResultsCountIsLimited;

/**
 The maximum number of public rooms to retrieve during a pagination. 
 Default is 20.
 */
@property (nonatomic) NSUInteger paginationLimit;

/**
 The flag indicating that all rooms has been retrieved from the homeserver.
 */
@property (nonatomic, readonly) BOOL hasReachedPaginationEnd;

/**
 The filter being applied. 
 
 Nil if there is no filter; the data source will get all public rooms.
 Default is nil.
 
 Setting a new value may trigger a request to the homeserver. So, the data source state
 may change to MXKDataSourceStatePreparing.
 */
@property (nonatomic) NSString *searchPattern;

/**
 Paginate more public rooms matching `from the homeserver.
 
 @param success A block object called when the operation succeeds. It provides the number of got rooms.
 @param failure A block object called when the operation fails.
 */
- (MXHTTPOperation*)paginate:(void (^)(NSUInteger roomsAdded))success
                     failure:(void (^)(NSError *error))failure;

/**
 Get the index path of the cell related to the provided roomId and session.

 @param roomId the room identifier.
 @param mxSession the matrix session in which the room should be available.
 @return indexPath the index of the cell (nil if not found or if the related section is shrinked).
 */
- (NSIndexPath*)cellIndexPathWithRoomId:(NSString*)roomId andMatrixSession:(MXSession*)mxSession;

/**
 Get the public at the given index path.
 
 @param indexPath the position of the room in the table view.
 @return the public room object.
 */
- (MXPublicRoom*)roomAtIndexPath:(NSIndexPath*)indexPath;

/**
 Get the height of the cell at the given index path.
 
 @param indexPath the index of the cell
 @return the cell height
 */
- (CGFloat)cellHeightAtIndexPath:(NSIndexPath*)indexPath;

@end
