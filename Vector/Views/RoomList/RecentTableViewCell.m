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

#import "RecentTableViewCell.h"

#import "AvatarGenerator.h"

#import "MXEvent.h"

#import "VectorDesignValues.h"

#import "MXRoom+Vector.h"

@implementation RecentTableViewCell

#pragma mark - Class methods

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Round image view
    [_roomAvatar.layer setCornerRadius:_roomAvatar.frame.size.width / 2];
    _roomAvatar.clipsToBounds = YES;
    
    self.roomTitle.textColor = VECTOR_TEXT_BLACK_COLOR;
}

- (void)render:(MXKCellData *)cellData
{
    id<MXKRecentCellDataStoring> roomCellData = (id<MXKRecentCellDataStoring>)cellData;
    if (roomCellData)
    {
        // Report computed values as is
        self.roomTitle.text = roomCellData.roomDisplayname;
        self.lastEventDate.text = roomCellData.lastEventDate;
        
        // Manage lastEventAttributedTextMessage optional property
        if ([roomCellData respondsToSelector:@selector(lastEventAttributedTextMessage)])
        {
            self.lastEventDescription.attributedText = roomCellData.lastEventAttributedTextMessage;
        }
        else
        {
            self.lastEventDescription.text = roomCellData.lastEventTextMessage;
        }
        
        // Notify unreads and bing
        if (roomCellData.unreadCount)
        {
            self.bingIndicator.hidden = NO;
            if (0 < roomCellData.unreadBingCount)
            {
                self.bingIndicator.backgroundColor = roomCellData.recentsDataSource.eventFormatter.bingTextColor;
                self.lastEventDate.textColor = self.bingIndicator.backgroundColor;
            }
            else
            {
                self.bingIndicator.backgroundColor = VECTOR_SILVER_COLOR;
                self.lastEventDate.textColor = VECTOR_TEXT_GRAY_COLOR;
            }
        }
        else
        {
            self.bingIndicator.hidden = YES;
            self.lastEventDate.textColor = VECTOR_TEXT_GRAY_COLOR;
        }
        
        self.roomAvatar.backgroundColor = [UIColor clearColor];
        
        [roomCellData.roomDataSource.room setRoomAvatarImageIn:self.roomAvatar];
    }
    else
    {
        self.lastEventDescription.text = @"";
    }
}

+ (CGFloat)heightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    // The height is fixed
    return 74;
}

@end
