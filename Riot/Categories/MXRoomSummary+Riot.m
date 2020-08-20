/*
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd
 
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

#import "MXRoomSummary+Riot.h"

#import "AvatarGenerator.h"

@implementation MXRoomSummary (Riot)

- (void)setRoomAvatarImageIn:(MXKImageView*)mxkImageView
{
    // Use the room display name to prepare the default avatar image.
    NSString *avatarDisplayName = self.displayname;
    UIImage* avatarImage = [AvatarGenerator generateAvatarForMatrixItem:self.roomId withDisplayName:avatarDisplayName];
    
    if (self.avatar)
    {
        mxkImageView.enableInMemoryCache = YES;
        
        [mxkImageView setImageURI:self.avatar
                         withType:nil
              andImageOrientation:UIImageOrientationUp
                    toFitViewSize:mxkImageView.frame.size
                       withMethod:MXThumbnailingMethodCrop
                     previewImage:avatarImage
                     mediaManager:self.mxSession.mediaManager];
    }
    else
    {
        mxkImageView.image = avatarImage;
    }
    
    mxkImageView.contentMode = UIViewContentModeScaleAspectFill;
}

- (RoomEncryptionTrustLevel)roomEncryptionTrustLevel
{
    RoomEncryptionTrustLevel roomEncryptionTrustLevel = RoomEncryptionTrustLevelUnknown;
    if (self.trust)
    {
        double trustedUsersPercentage = self.trust.trustedUsersProgress.fractionCompleted;
        double trustedDevicesPercentage = self.trust.trustedDevicesProgress.fractionCompleted;

        if (trustedUsersPercentage >= 1.0)
        {
            if (trustedDevicesPercentage >= 1.0)
            {
                roomEncryptionTrustLevel = RoomEncryptionTrustLevelTrusted;
            }
            else
            {
                roomEncryptionTrustLevel = RoomEncryptionTrustLevelWarning;
            }
        }
        else
        {
            roomEncryptionTrustLevel = RoomEncryptionTrustLevelNormal;
        }
            
        roomEncryptionTrustLevel = roomEncryptionTrustLevel;
    }
    
    return roomEncryptionTrustLevel;
}

@end
