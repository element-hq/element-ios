/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "Contact.h"

#import "AvatarGenerator.h"

@implementation Contact

- (UIImage*)thumbnailWithPreferedSize:(CGSize)size
{
    UIImage* thumbnail = nil;
    
    // replace the identicon icon by the Vector style one
    if (_mxMember && ([_mxMember.avatarUrl rangeOfString:@"identicon"].location != NSNotFound))
    {        
        thumbnail = [AvatarGenerator generateAvatarForMatrixItem:_mxMember.userId withDisplayName:_mxMember.displayname];
    }
    else
    {
        thumbnail = [super thumbnailWithPreferedSize:size];
    }
    
    // ensure that the thumbnail will have a vector style.
    if (!thumbnail)
    {
        thumbnail = [AvatarGenerator generateAvatarForText:self.displayName];
    }
    
    return thumbnail;
}

@end
