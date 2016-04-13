/*
 Copyright 2015 OpenMarket Ltd
 
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

#import "Contact.h"

#import "AvatarGenerator.h"

@implementation Contact

- (UIImage*)thumbnailWithPreferedSize:(CGSize)size
{
    UIImage* thumbnail = nil;
    
    // replace the identicon icon by the Vector style one
    if (_mxMember && ([_mxMember.avatarUrl rangeOfString:@"identicon"].location != NSNotFound))
    {        
        thumbnail = [AvatarGenerator generateRoomMemberAvatar:_mxMember.userId displayName:_mxMember.displayname];
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

- (NSString*)sortingDisplayName
{
    if (!_sortingDisplayName)
    {
        // Sanity check - display name should not be nil here
        if (self.displayName)
        {
            NSCharacterSet *specialCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"_!~`@#$%^&*-+();:={}[],.<>?\\/\"\'"];
            
            _sortingDisplayName = [self.displayName stringByTrimmingCharactersInSet:specialCharacterSet];
        }
        else
        {
            return @"";
        }
    }
    
    return _sortingDisplayName;
}

@end
