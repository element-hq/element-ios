/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomBubbleCellData.h"

/**
 `MXKRoomBubbleCellDataWithAppendingMode` class inherits from `MXKRoomBubbleCellData`, it merges
 consecutive events from the same sender into one bubble.
 Each concatenated event is represented by a bubble component.
 */
@interface MXKRoomBubbleCellDataWithAppendingMode : MXKRoomBubbleCellData
{
@protected
    /**
     YES if position of each component must be refreshed
     */
    BOOL shouldUpdateComponentsPosition;
}

/**
 The string appended to the current message before adding a new component text.
 */
+ (NSAttributedString *)messageSeparator;

/**
 The maximum number of components in each bubble. Default is 10.
 We limit the number of components to reduce the computation time required during bubble handling.
 Indeed some process like [prepareBubbleComponentsPosition] is time consuming.
 */
@property (nonatomic) NSUInteger maxComponentCount;

@end
