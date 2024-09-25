/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomMembershipExpandedBubbleCell.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#import "RoomBubbleCellData.h"

NSString *const kRoomMembershipExpandedBubbleCellTapOnCollapseButton = @"kRoomMembershipExpandedBubbleCellTapOnCollapseButton";

@implementation RoomMembershipExpandedBubbleCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    NSString* title = [VectorL10n collapse];
    [self.collapseButton setTitle:title forState:UIControlStateNormal];
    [self.collapseButton setTitle:title forState:UIControlStateHighlighted];
}

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.separatorView.backgroundColor = ThemeService.shared.theme.lineBreakColor;
    
    [self.collapseButton setTintColor:ThemeService.shared.theme.tintColor];
    self.collapseButton.titleLabel.font = [UIFont systemFontOfSize:14];
}

- (IBAction)onCollapseButtonTap:(id)sender
{
    if (self.delegate)
    {
        [self.delegate cell:self didRecognizeAction:kRoomMembershipExpandedBubbleCellTapOnCollapseButton userInfo:nil];
    }
}

@end
