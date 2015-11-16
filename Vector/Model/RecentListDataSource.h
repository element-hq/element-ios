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
 The data source for `RecentsViewController` in Vector
 List the recents (interleaved in only one section in case of multi-sessions) and the available public rooms.
 A section of public rooms is added for each added REST client.
 
 Two different types of cell data are handled by this data source: id<MXKRecentCellDataStoring> for the recents
 and MXPublicRoom* for the public rooms added after the recents list.
 See publicRoomsFirstSection property to know which type is expected for cell data at a specific indexPath.
 */
@interface RecentListDataSource : MXKInterleavedRecentsDataSource

/**
 The first Public rooms sections (-1 if none).
 */
@property NSInteger publicRoomsFirstSection;

/**
 Add a matrix REST Client. It is used to retrieve public rooms.
 
 @param restClient a restClient.
 @param onComplete the callback called once public rooms are updated for this client.
 */
- (void)addRestClient:(MXRestClient*)restClient onComplete:(void (^)())onComplete;

/**
 Remove a matrix REST Client.
 */
- (void)removeRestClient:(MXRestClient*)restClient;

/**
 Refresh public rooms
 
 @param restClient a restClient, or nil to refresh public rooms for all added client.
 @param onComplete the callback called once public rooms are updated.
 */
- (void)refreshPublicRooms:(MXRestClient*)restClient onComplete:(void (^)())onComplete;

/**
 Get the public room displayed in the cell at the given index path.
 
 @param indexPath the index of the cell
 @return a public room or nil if the provided indexPath does not correspond to a public room section.
 */
- (MXPublicRoom*)publicRoomAtIndexPath:(NSIndexPath*)indexPath;

@end
