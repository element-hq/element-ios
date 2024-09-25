/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

#import "SegmentedViewController.h"

@interface RoomSearchViewController : SegmentedViewController

/**
 The room data source concerned by the search session.
 */
@property (nonatomic) MXKRoomDataSource *roomDataSource;

+ (instancetype)instantiate;

- (void)selectEvent:(MXEvent *)event;

@end
