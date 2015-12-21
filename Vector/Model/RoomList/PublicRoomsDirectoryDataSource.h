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

#import <Foundation/Foundation.h>

#import "MatrixKit/MatrixKit.h"

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
@interface PublicRoomsDirectoryDataSource : MXKDataSource <UITableViewDataSource>

/**
 All public rooms of the directory.
 */
@property (nonatomic, readonly) NSArray<MXPublicRoom*> *rooms;

/**
 The filter being applied. Nil if there is no filter.
 A 'OR' search is made on the strings of the array. 
 Setting a new value may trigger a request to the home server. So, the data source state
 may change to MXKDataSourceStatePreparing.
 */
@property (nonatomic) NSArray<NSString*> *searchPatternsList;

/**
 Public rooms of the directory that match `searchPatternsList`.
 */
@property (nonatomic, readonly) NSArray<MXPublicRoom*> *filteredRooms;

@end
