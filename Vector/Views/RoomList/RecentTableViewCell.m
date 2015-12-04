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

@implementation RecentTableViewCell

#pragma mark - Class methods

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Round image view
    [_roomAvatar.layer setCornerRadius:_roomAvatar.frame.size.width / 2];
    _roomAvatar.clipsToBounds = YES;
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
        self.bingIndicator.hidden = YES;
        
        if (roomCellData.unreadCount)
        {
            if (0 < roomCellData.unreadBingCount)
            {
                self.bingIndicator.hidden = NO;
                self.bingIndicator.backgroundColor = roomCellData.recentsDataSource.eventFormatter.bingTextColor;
            }
            self.roomTitle.font = [UIFont boldSystemFontOfSize:19];
        }
        else
        {
            self.roomTitle.font = [UIFont systemFontOfSize:19];
        }
        
        self.roomAvatar.backgroundColor = [UIColor clearColor];

        MXRoom* room = roomCellData.roomDataSource.room;
        
        NSString* roomAvatarUrl = room.state.avatar;
        
        // detect if it is a room with no more than 2 members (i.e. an alone or a 1:1 chat)
        if (!roomAvatarUrl)
        {
            NSString* myUserId = room.mxSession.myUser.userId;
            
            NSArray* members = room.state.members;
            
            if (members.count < 3)
            {
                // use the member avatar only it is an active member
                for (MXRoomMember *roomMember in members)
                {
                    if ((MXMembershipJoin == roomMember.membership) && ((members.count == 1) || ![roomMember.userId isEqualToString:myUserId]))
                    {
                        roomAvatarUrl = roomMember.avatarUrl;
                        break;
                    }
                }
            }
        }
                
        UIImage* avatarImage = [AvatarGenerator generateRoomAvatar:room];
        
        if (roomAvatarUrl)
        {
            self.roomAvatar.enableInMemoryCache = YES;
            
            [self.roomAvatar setImageURL:[roomCellData.roomDataSource.mxSession.matrixRestClient urlOfContentThumbnail:roomAvatarUrl toFitViewSize:self.roomAvatar.frame.size withMethod:MXThumbnailingMethodCrop] withType:nil andImageOrientation:UIImageOrientationUp previewImage:avatarImage];
        }
        else
        {
            self.roomAvatar.image = avatarImage;
        }
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
