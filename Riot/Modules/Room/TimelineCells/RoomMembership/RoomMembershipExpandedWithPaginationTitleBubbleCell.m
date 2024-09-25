/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomMembershipExpandedWithPaginationTitleBubbleCell.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#import "RoomBubbleCellData.h"

@implementation RoomMembershipExpandedWithPaginationTitleBubbleCell

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];

    self.paginationLabel.textColor = ThemeService.shared.theme.tintColor;
    self.paginationSeparatorView.backgroundColor = ThemeService.shared.theme.tintColor;
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];

    if (bubbleData)
    {
        self.paginationLabel.text = [[bubbleData.eventFormatter dateStringFromDate:bubbleData.date withTime:NO] uppercaseString];
    }
}

@end
