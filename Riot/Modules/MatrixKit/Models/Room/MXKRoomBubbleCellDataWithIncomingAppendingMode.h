/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomBubbleCellDataWithAppendingMode.h"

/**
 `MXKRoomBubbleCellDataWithIncomingAppendingMode` class inherits from `MXKRoomBubbleCellDataWithAppendingMode`, 
  only the incoming message cells are merged.
 */
@interface MXKRoomBubbleCellDataWithIncomingAppendingMode : MXKRoomBubbleCellDataWithAppendingMode
{
}

@end
