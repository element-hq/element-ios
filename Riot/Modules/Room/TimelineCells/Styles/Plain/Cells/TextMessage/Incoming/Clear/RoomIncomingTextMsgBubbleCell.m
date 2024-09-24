/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

#import "RoomIncomingTextMsgBubbleCell.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"
#import "MXKRoomBubbleTableViewCell+Riot.h"

@implementation RoomIncomingTextMsgBubbleCell

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    [self updateUserNameColor];
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];
    
    [self updateUserNameColor];
}

@end
