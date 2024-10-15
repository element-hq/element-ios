/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomOutgoingTextMsgBubbleCell.h"

#import "GeneratedInterface-Swift.h"

@implementation MXKRoomOutgoingTextMsgBubbleCell

- (void)setupViews
{
    [super setupViews];
    
    RoomTimelineConfiguration *timelineConfiguration = [RoomTimelineConfiguration shared];
        
    [timelineConfiguration.currentStyle.cellLayoutUpdater setupLayoutForOutgoingTextMessageCell:self];
}


@end
