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

#import "MatrixKit.h"

/**
 `RoomSearchDataSource` overrides `MXKSearchDataSource` to render search results
 into the same cells as `RoomViewController`.
 */
@interface RoomSearchDataSource : MXKSearchDataSource

/**
 Initialize a new `RoomSearchDataSource` instance.
 
 @param roomDataSource a datasource to be able to reuse `RoomViewController` processing and rendering.
 @return the newly created instance.
 */
- (instancetype)initWithRoomDataSource:(MXKRoomDataSource *)roomDataSource;

@end
