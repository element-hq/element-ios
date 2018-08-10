/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "PublicRoomTableViewCell.h"

#import "AvatarGenerator.h"

#import "RiotDesignValues.h"

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
    
    self.roomDisplayName.textColor = kRiotPrimaryTextColor;
    self.roomTopic.textColor = kRiotSecondaryTextColor;
    self.memberCount.textColor = kRiotSecondaryTextColor;
    
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

        [_roomAvatar setImageURL:[mxSession.matrixRestClient urlOfContentThumbnail:publicRoom.avatarUrl
                                                                    toFitViewSize:_roomAvatar.frame.size
                                                                       withMethod:MXThumbnailingMethodCrop]
                        withType:nil
             andImageOrientation:UIImageOrientationUp previewImage:avatarImage];
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
