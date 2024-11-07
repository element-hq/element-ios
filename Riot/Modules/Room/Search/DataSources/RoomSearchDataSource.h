/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
