/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MessagesSearchResultAttachmentBubbleCell.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"
#import "MXKRoomBubbleTableViewCell+Riot.h"

@implementation MessagesSearchResultAttachmentBubbleCell

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.roomNameLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
        
    [self updateUserNameColor];
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];
    
    if (bubbleData)
    {
        MXRoom* room = [bubbleData.mxSession roomWithRoomId:bubbleData.roomId];
        if (room)
        {
            self.roomNameLabel.text = room.summary.displayName;
            if (!self.roomNameLabel.text.length)
            {
                self.roomNameLabel.text = [VectorL10n roomDisplaynameEmptyRoom];
            }
        }
        else
        {
            self.roomNameLabel.text = bubbleData.roomId;
        }
        
        [self updateUserNameColor];
    }
}

@end
