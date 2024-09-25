/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomBubbleCellDataWithIncomingAppendingMode.h"

@implementation MXKRoomBubbleCellDataWithIncomingAppendingMode

#pragma mark - MXKRoomBubbleCellDataStoring

- (BOOL)addEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState
{
    // Do not merge outgoing events
    if  ([event.sender isEqualToString:roomDataSource.mxSession.myUser.userId])
    {
        return NO;
    }
    
    return [super addEvent:event andRoomState:roomState];
}

- (BOOL)mergeWithBubbleCellData:(id<MXKRoomBubbleCellDataStoring>)bubbleCellData
{
    // Do not merge outgoing events
    if  ([bubbleCellData.senderId isEqualToString:roomDataSource.mxSession.myUser.userId])
    {
        return NO;
    }
    
    return [super mergeWithBubbleCellData:bubbleCellData];
}

@end
