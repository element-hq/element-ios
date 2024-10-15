/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RecentsDataSource.h"

/**
 'UnifiedSearchRecentsDataSource' class inherits from 'RecentsDataSource' to define the Riot recents source
 used during the unified search on rooms.
 */
@interface UnifiedSearchRecentsDataSource : RecentsDataSource

#pragma mark - Directory handling

/**
 Hide recents. NO by default.
 */
@property (nonatomic) BOOL hideRecents;

@end
