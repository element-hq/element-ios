/*
 Copyright 2016 OpenMarket Ltd
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

#import "RoomAvatarTitleView.h"

#import "RiotDesignValues.h"

#import "MXRoom+Riot.h"

@implementation RoomAvatarTitleView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([self class])
                          bundle:[NSBundle bundleForClass:[self class]]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.superview)
    {
        // Center horizontally the avatar into the navigation bar
        CGRect frame = self.superview.frame;
        UINavigationBar *navigationBar;
        UIView *superView = self;
        while (superView.superview)
        {
            if ([superView.superview isKindOfClass:[UINavigationBar class]])
            {
                navigationBar = (UINavigationBar*)superView.superview;
                break;
            }
            
            superView = superView.superview;
        }
        
        if (navigationBar)
        {
            CGSize navBarSize = navigationBar.frame.size;
            CGFloat superviewCenterX = frame.origin.x + (frame.size.width / 2);
            
            self.roomAvatarCenterXConstraint.constant = (navBarSize.width / 2) - superviewCenterX;
        }
    }
}

- (void)refreshDisplay
{
    [super refreshDisplay];
    
    if (self.mxRoom)
    {
        [self.mxRoom setRoomAvatarImageIn:self.roomAvatar];
    }
    else if (self.roomAvatarURL)
    {
        [self.roomAvatar setImageURL:self.roomAvatarURL withType:nil andImageOrientation:UIImageOrientationUp previewImage:[UIImage imageNamed:@"placeholder"]];
    }
    else if (self.roomAvatarPlaceholder)
    {
        self.roomAvatar.image = self.roomAvatarPlaceholder;
    }
    else
    {
        self.roomAvatar.image = nil;
    }
    
    // Round image view for thumbnail
    self.roomAvatar.layer.cornerRadius = self.roomAvatar.frame.size.width / 2;
    self.roomAvatar.clipsToBounds = YES;
    
    self.roomAvatar.backgroundColor = kRiotSecondaryBgColor;
}

- (void)setRoomAvatarURL:(NSString *)roomAvatarURL
{
    _roomAvatarURL = roomAvatarURL;
    
    [self refreshDisplay];
}

- (void)setRoomAvatarPlaceholder:(UIImage *)roomAvatarPlaceholder
{
    _roomAvatarPlaceholder = roomAvatarPlaceholder;
    
    [self refreshDisplay];
}

@end
