/*
Copyright 2024 New Vector Ltd.
Copyright 2021 The Matrix.org Foundation C.I.C

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomDataSource+Tests.h"

@implementation MXKRoomDataSource (Tests)

- (NSArray<id<MXKRoomBubbleCellDataStoring>> *)getBubbles {
    return bubbles;
}

- (void)replaceBubbles:(NSArray<id<MXKRoomBubbleCellDataStoring>> *)newBubbles {
    bubbles = [NSMutableArray arrayWithArray:newBubbles];
}

@end
