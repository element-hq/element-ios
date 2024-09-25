/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomTableViewCell.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#import "MXRoomSummary+Riot.h"

@implementation RoomTableViewCell

#pragma mark - Class methods

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.titleLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    
    self.avatarImageView.defaultBackgroundColor = [UIColor clearColor];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Round image view
    [self.avatarImageView.layer setCornerRadius:self.avatarImageView.frame.size.width / 2];
    self.avatarImageView.clipsToBounds = YES;
}

- (void)render:(MXRoom *)room
{
    [room.summary setRoomAvatarImageIn:self.avatarImageView];
    
    self.titleLabel.text = room.summary.displayName;
}

+ (CGFloat)cellHeight
{
    return 74;
}

@end
