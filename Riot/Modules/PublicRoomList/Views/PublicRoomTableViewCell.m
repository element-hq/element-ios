/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "PublicRoomTableViewCell.h"

#import "AvatarGenerator.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

@implementation PublicRoomTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    // Round image view
    [_roomAvatar.layer setCornerRadius:_roomAvatar.frame.size.width / 2];
    _roomAvatar.clipsToBounds = YES;
}

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.roomDisplayName.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.roomTopic.textColor = ThemeService.shared.theme.textSecondaryColor;
    self.memberCount.textColor = ThemeService.shared.theme.textSecondaryColor;
    
    _roomAvatar.defaultBackgroundColor = [UIColor clearColor];
}

- (void)render:(MXPublicRoom *)publicRoom withMatrixSession:(MXSession*)mxSession
{
    [super render:publicRoom];

    // Set room display name a la Vector
    self.roomDisplayName.text = publicRoom.name;
    if (!self.roomDisplayName.text)
    {
        self.roomDisplayName.text = publicRoom.aliases[0];
    }

    // Set the avatar
    UIImage* avatarImage = [AvatarGenerator generateAvatarForMatrixItem:publicRoom.roomId withDisplayName:self.roomDisplayName.text];

    if (publicRoom.avatarUrl)
    {
        _roomAvatar.enableInMemoryCache = YES;

        [_roomAvatar setImageURI:publicRoom.avatarUrl
                        withType:nil
             andImageOrientation:UIImageOrientationUp
                   toFitViewSize:_roomAvatar.frame.size
                      withMethod:MXThumbnailingMethodCrop
                    previewImage:avatarImage
                    mediaManager:mxSession.mediaManager];
    }
    else
    {
        _roomAvatar.image = avatarImage;
    }
    
    _roomAvatar.contentMode = UIViewContentModeScaleAspectFill;
}

+ (CGFloat)cellHeight
{
    return 74;
}

@end
