/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomMembershipBubbleCell.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#import "RoomBubbleCellData.h"

@interface RoomMembershipBubbleCell ()
{
    CGFloat xibPictureViewTopConstraintConstant;
}
@end

@implementation RoomMembershipBubbleCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    // Get original xib values
    xibPictureViewTopConstraintConstant = self.pictureViewTopConstraint.constant;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    if (self.pictureViewTopConstraint.constant != xibPictureViewTopConstraintConstant)
    {
        self.pictureViewTopConstraint.constant = xibPictureViewTopConstraintConstant;
    }
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];

    RoomBubbleCellData *data = (RoomBubbleCellData*)cellData;

    // If the text was moved down (selected cell or last event), do the same for the icon
    if ((data.containsLastMessage || data.selectedComponentIndex != NSNotFound)
        && [data.attributedTextMessage.string hasPrefix:@"\n"])
    {
        self.pictureViewTopConstraint.constant = xibPictureViewTopConstraintConstant + 14;
    }
}

@end
