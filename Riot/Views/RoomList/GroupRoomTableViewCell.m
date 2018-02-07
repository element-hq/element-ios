/*
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

#import "GroupRoomTableViewCell.h"

#import "AvatarGenerator.h"

#import "RiotDesignValues.h"

@implementation GroupRoomTableViewCell

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
    
    _roomAvatar.defaultBackgroundColor = [UIColor clearColor];
}

- (void)render:(MXGroupRoom *)groupRoom withMatrixSession:(MXSession*)mxSession
{
    // Set room display name
    self.roomDisplayName.text = groupRoom.name;
    if (!self.roomDisplayName.text)
    {
        self.roomDisplayName.text = groupRoom.canonicalAlias;
    }
    if (!self.roomDisplayName.text)
    {
        self.roomDisplayName.text = groupRoom.roomId;
    }
    
    // Check whether this room has topic
    if (groupRoom.topic)
    {
        _roomTopic.hidden = NO;
        _roomTopic.text = [MXTools stripNewlineCharacters:groupRoom.topic];
    }
    else
    {
        // Hide and fill the label with a fake description to harmonize the height of all the cells.
        // This is a drawback of the self-sizing cell.
        _roomTopic.hidden = YES;
        _roomTopic.text = @"No topic";
    }

    // Set the avatar
    UIImage* avatarImage = [AvatarGenerator generateAvatarForMatrixItem:groupRoom.roomId withDisplayName:self.roomDisplayName.text];

    if (groupRoom.avatarUrl)
    {
        _roomAvatar.enableInMemoryCache = YES;

        [_roomAvatar setImageURL:[mxSession.matrixRestClient urlOfContentThumbnail:groupRoom.avatarUrl
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

@end
