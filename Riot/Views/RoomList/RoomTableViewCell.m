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

#import "RoomTableViewCell.h"

#import "RiotDesignValues.h"
#import "MXRoom+Vector.h"

@implementation RoomTableViewCell

#pragma mark - Class methods

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.titleLabel.textColor = kRiotTextColorBlack;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Round image view
    [self.avatarImageView.layer setCornerRadius:self.avatarImageView.frame.size.width / 2];
    self.avatarImageView.clipsToBounds = YES;
}

- (void)render:(MXRoom *)room
{
    [room setRoomAvatarImageIn:self.avatarImageView];
    self.avatarImageView.backgroundColor = [UIColor clearColor];
    
    self.titleLabel.text = room.vectorDisplayname;
}

+ (CGFloat)cellHeight
{
    return 74;
}

@end
