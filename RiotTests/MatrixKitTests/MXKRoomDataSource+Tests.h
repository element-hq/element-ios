/*
Copyright 2024 New Vector Ltd.
Copyright 2021 The Matrix.org Foundation C.I.C

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomDataSource.h"

@interface MXKRoomDataSource (Tests)

- (NSArray<id<MXKRoomBubbleCellDataStoring>> *)getBubbles;
- (void)replaceBubbles:(NSArray<id<MXKRoomBubbleCellDataStoring>> *)newBubbles;

- (void)queueEventForProcessing:(MXEvent*)event withRoomState:(MXRoomState*)roomState direction:(MXTimelineDirection)direction;
- (void)processQueuedEvents:(void (^)(NSUInteger addedHistoryCellNb, NSUInteger addedLiveCellNb))onComplete;

@end
