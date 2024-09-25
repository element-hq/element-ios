/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomIdOrAliasTableViewCell.h"

#import "AvatarGenerator.h"
#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

@implementation RoomIdOrAliasTableViewCell

#pragma mark - Class methods

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.titleLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Round image view
    [self.avatarImageView.layer setCornerRadius:self.avatarImageView.frame.size.width / 2];
    self.avatarImageView.clipsToBounds = YES;
}

- (void)render:(NSString *)roomIdOrAlias
{
    if (roomIdOrAlias)
    {
        self.avatarImageView.image = [AvatarGenerator generateAvatarForText:roomIdOrAlias];
    }
    else
    {
        self.avatarImageView.image = [MXKTools paintImage:AssetImages.placeholder.image
                                                withColor:ThemeService.shared.theme.tintColor];
    }
    
    self.titleLabel.text = roomIdOrAlias;
}

+ (CGFloat)cellHeight
{
    return 74;
}

@end
