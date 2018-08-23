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

#import "GroupTableViewCell.h"

#import "RiotDesignValues.h"

#import "MXGroup+Riot.h"

@implementation GroupTableViewCell

#pragma mark - Class methods

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if (self.missedNotifAndUnreadBadgeBgView)
    {
        // Initialize unread count badge
        [_missedNotifAndUnreadBadgeBgView.layer setCornerRadius:10];
        _missedNotifAndUnreadBadgeBgViewWidthConstraint.constant = 0;
    }
}

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.groupName.textColor = kRiotPrimaryTextColor;
    self.groupDescription.textColor = kRiotSecondaryTextColor;
    self.memberCount.textColor = kRiotSecondaryTextColor;
    
    if (self.missedNotifAndUnreadBadgeLabel)
    {
        self.missedNotifAndUnreadBadgeLabel.textColor = kRiotPrimaryBgColor;
    }
    
    self.groupAvatar.defaultBackgroundColor = [UIColor clearColor];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Round image view
    [_groupAvatar.layer setCornerRadius:_groupAvatar.frame.size.width / 2];
    _groupAvatar.clipsToBounds = YES;
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];
    
    if (self.missedNotifAndUnreadBadgeBgView)
    {
        // Hide by default missed notifications and unread widgets
        self.missedNotifAndUnreadBadgeBgView.hidden = YES;
        self.missedNotifAndUnreadBadgeBgViewWidthConstraint.constant = 0;
    }
    
    if (groupCellData)
    {
        [groupCellData.group setGroupAvatarImageIn:self.groupAvatar matrixSession:groupCellData.groupsDataSource.mxSession];
    }
}

// @TODO: Remove this method required by `MXKCellRendering` protocol.
// It is not used for the groups table view.
+ (CGFloat)heightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    // The height is fixed
    // @TODO change this to support dynamic fonts
    return 74;
}

@end
