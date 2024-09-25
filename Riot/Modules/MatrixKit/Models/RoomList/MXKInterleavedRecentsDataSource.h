/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRecentsDataSource.h"

/**
 'MXKInterleavedRecentsDataSource' class inherits from 'MXKRecentsDataSource'.
 
 It interleaves the recents in case of multiple sessions to display first the most recent room.
 */
@interface MXKInterleavedRecentsDataSource : MXKRecentsDataSource

@end
