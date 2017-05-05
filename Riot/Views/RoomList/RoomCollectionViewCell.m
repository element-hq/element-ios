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

#import "RoomCollectionViewCell.h"

#import "AvatarGenerator.h"

#import "RiotDesignValues.h"

#import "MXRoom+Riot.h"

@implementation RoomCollectionViewCell

#pragma mark - Class methods

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Initialize unread count badge
    [_missedNotifAndUnreadBadgeBgView.layer setCornerRadius:10];
    _missedNotifAndUnreadBadgeBgViewWidthConstraint.constant = 0;
    
    self.roomTitle.textColor = kRiotTextColorBlack;
    self.missedNotifAndUnreadBadgeLabel.textColor = [UIColor whiteColor];
    
    self.directRoomBorderView.backgroundColor = kRiotColorGreen;
    self.directRoomBorderView.alpha = 0.75;
    [self.directRoomBorderView.layer setCornerRadius:self.directRoomBorderView.frame.size.width / 2];
    self.directRoomBorderView.clipsToBounds = YES;
    
    // Disable the user interaction on the room avatar.
    self.roomAvatar.userInteractionEnabled = NO;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Round image view
    [_roomAvatar.layer setCornerRadius:_roomAvatar.frame.size.width / 2];
    _roomAvatar.clipsToBounds = YES;
}

- (void)render:(MXKCellData *)cellData
{
    // Hide by default missed notifications and unread widgets
    self.missedNotifAndUnreadBadgeBgView.hidden = YES;
    self.missedNotifAndUnreadBadgeBgViewWidthConstraint.constant = 0;
    
    roomCellData = (id<MXKRecentCellDataStoring>)cellData;
    if (roomCellData)
    {
        // Report computed values as is
        self.roomTitle.text = roomCellData.roomDisplayname;
        
        // Notify unreads and bing
        if (roomCellData.hasUnread)
        {
            if (0 < roomCellData.notificationCount)
            {
                self.missedNotifAndUnreadBadgeBgView.hidden = NO;
                self.missedNotifAndUnreadBadgeBgView.backgroundColor = roomCellData.highlightCount ? kRiotColorPinkRed : kRiotColorGreen;
                
                self.missedNotifAndUnreadBadgeLabel.text = [NSString stringWithFormat:@"%tu", roomCellData.notificationCount];
                [self.missedNotifAndUnreadBadgeLabel sizeToFit];
                
                self.missedNotifAndUnreadBadgeBgViewWidthConstraint.constant = self.missedNotifAndUnreadBadgeLabel.frame.size.width + 18;
            }
            
            // Use bold font for the room title
            if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)])
            {
                self.roomTitle.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
            }
            else
            {
                self.roomTitle.font = [UIFont boldSystemFontOfSize:15];
            }
        }
        else
        {
            // The room title is not bold anymore
            if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)])
            {
                self.roomTitle.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
            }
            else
            {
                self.roomTitle.font = [UIFont systemFontOfSize:15];
            }
        }
        
        self.roomAvatar.backgroundColor = [UIColor clearColor];
        
        self.directRoomBorderView.hidden = !roomCellData.roomSummary.room.isDirect;
        
        self.encryptedRoomIcon.hidden = !roomCellData.roomSummary.isEncrypted;
        
        [roomCellData.roomSummary.room setRoomAvatarImageIn:self.roomAvatar];
    }
}

+ (CGFloat)heightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    // The height is fixed
    return 110;
}

+ (CGSize)defaultCellSize
{
    return CGSizeMake(90, 110);
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    // Remove all gesture recognizers
    while (self.gestureRecognizers.count)
    {
        [self removeGestureRecognizer:self.gestureRecognizers[0]];
    }
    self.tag = -1;
}

@end

