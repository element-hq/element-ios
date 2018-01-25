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

#import "MXGroup+Riot.h"

#import "AvatarGenerator.h"

@implementation MXGroup (Riot)

- (void)setGroupAvatarImageIn:(MXKImageView*)mxkImageView matrixSession:(MXSession*)mxSession
{
    // Use the group display name to prepare the default avatar image.
    NSString *avatarDisplayName = self.profile.name;
    UIImage* avatarImage = [AvatarGenerator generateAvatarForMatrixItem:self.groupId withDisplayName:avatarDisplayName];
    
    if (self.profile.avatarUrl && mxSession)
    {
        mxkImageView.enableInMemoryCache = YES;
        
        [mxkImageView setImageURL:[mxSession.matrixRestClient urlOfContentThumbnail:self.profile.avatarUrl toFitViewSize:mxkImageView.frame.size withMethod:MXThumbnailingMethodCrop] withType:nil andImageOrientation:UIImageOrientationUp previewImage:avatarImage];
    }
    else
    {
        mxkImageView.image = avatarImage;
    }
    
    mxkImageView.contentMode = UIViewContentModeScaleAspectFill;
}

@end
