/*
 Copyright 2016 OpenMarket Ltd
 
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

#import "VectorDesignValues.h"

#import "MXRoom+Vector.h"

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
        // Center horizontally the avatar according to the actual screen center
        CGRect frame = self.superview.frame;
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        
        CGFloat superviewCenterX = frame.origin.x + (frame.size.width / 2);
        
        self.roomAvatarCenterXConstraint.constant = (screenSize.width / 2) - superviewCenterX;
    }
}

- (void)refreshDisplay
{
    [super refreshDisplay];
    
    if (self.mxRoom)
    {
        [self.mxRoom setRoomAvatarImageIn:self.roomAvatar];
        
        // Round image view for thumbnail
        self.roomAvatar.layer.cornerRadius = self.roomAvatar.frame.size.width / 2;
        self.roomAvatar.clipsToBounds = YES;
        
    }
    else
    {
        self.roomAvatar.image = [UIImage imageNamed:@"placeholder"];
    }    
    
    self.roomAvatar.backgroundColor = kVectorColorLightGrey;
}

@end
