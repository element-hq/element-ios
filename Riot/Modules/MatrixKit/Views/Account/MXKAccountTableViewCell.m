/*
 Copyright 2015 OpenMarket Ltd
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

#import "MXKAccountTableViewCell.h"

@import MatrixSDK.MXMediaManager;

#import "NSBundle+MatrixKit.h"

@implementation MXKAccountTableViewCell

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.accountPicture.defaultBackgroundColor = [UIColor clearColor];
}

- (void)setMxAccount:(MXKAccount *)mxAccount
{
    UIColor *presenceColor = nil;
    
    _accountDisplayName.text = mxAccount.fullDisplayName;
    
    if (mxAccount.mxSession)
    {
        _accountPicture.mediaFolder = kMXMediaManagerAvatarThumbnailFolder;
        _accountPicture.enableInMemoryCache = YES;
        [_accountPicture setImageURI:mxAccount.userAvatarUrl
                            withType:nil
                 andImageOrientation:UIImageOrientationUp
                       toFitViewSize:_accountPicture.frame.size
                          withMethod:MXThumbnailingMethodCrop
                        previewImage:self.picturePlaceholder
                        mediaManager:mxAccount.mxSession.mediaManager];
        
        presenceColor = [MXKAccount presenceColor:mxAccount.userPresence];
    }
    else
    {
        _accountPicture.image = self.picturePlaceholder;
    }
    
    if (presenceColor)
    {
        _accountPicture.layer.borderWidth = 2;
        _accountPicture.layer.borderColor = presenceColor.CGColor;
    }
    else
    {
        _accountPicture.layer.borderWidth = 0;
    }
    
    _accountSwitchToggle.on = !mxAccount.disabled;
    if (mxAccount.disabled)
    {
        _accountDisplayName.textColor = [UIColor lightGrayColor];
    }
    else
    {
        _accountDisplayName.textColor = [UIColor blackColor];
    }
    
    _mxAccount = mxAccount;
}

- (UIImage*)picturePlaceholder
{
    return [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"default-profile"];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Round image view
    [_accountPicture.layer setCornerRadius:_accountPicture.frame.size.width / 2];
    _accountPicture.clipsToBounds = YES;
}

@end
