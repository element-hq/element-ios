/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXRoom+Sync.h"

@implementation MXRoom (Sync)

- (MXRoomState *)dangerousSyncState
{
    __block MXRoomState *syncState;

    // If syncState is called from the right place, the following call will be
    // synchronous and every thing will be fine
    [self state:^(MXRoomState *roomState) {
        syncState = roomState;
    }];

    NSAssert(syncState, @"[MXRoom+Sync] syncState failed. Are you sure the state of the room has been already loaded?");

    return syncState;
}

@end
