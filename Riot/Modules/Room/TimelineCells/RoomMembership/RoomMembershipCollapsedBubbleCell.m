/*
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

#import "RoomMembershipCollapsedBubbleCell.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#import "RoomBubbleCellData.h"

#import "AvatarGenerator.h"

@implementation RoomMembershipCollapsedBubbleCell

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];

    self.messageTextView.tintColor = ThemeService.shared.theme.tintColor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    // Round avatars
    for (UIView *avatarView in self.avatarsView.subviews)
    {
        [avatarView.layer setCornerRadius:avatarView.frame.size.width / 2];
        avatarView.clipsToBounds = YES;
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    // Reset avatars
    for (UIView *avatarView in self.avatarsView.subviews)
    {
        [avatarView removeFromSuperview];
    }
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];

    // Add up to 5 avatars to self.avatarsView
    RoomBubbleCellData *nextBubbleData = (RoomBubbleCellData*)bubbleData;

    do
    {
        MXKImageView *avatarView = [[MXKImageView alloc] initWithFrame:CGRectMake(12 * self.avatarsView.subviews.count, 0, 16, 16)];

        // Handle user's picture by considering it is stored unencrypted on Matrix media repository
        avatarView.enableInMemoryCache = YES;
        
        UIImage *avatarPlaceholder;
        NSString *avatarUrl;

        MXEvent *firstEvent = nextBubbleData.events.firstObject;
        MXRoomMemberEventContent *content = [MXRoomMemberEventContent modelFromJSON:firstEvent.content];
        
        // We want to display the avatar of the invitee.
        // In case of a join event, the invitee is the sender. Otherwise, the invitee is the target.
        if (![content.membership isEqualToString:kMXMembershipStringJoin])
        {
            // Use the Riot style placeholder
            if (!nextBubbleData.targetAvatarPlaceholder)
            {
                nextBubbleData.targetAvatarPlaceholder = [AvatarGenerator generateAvatarForMatrixItem:nextBubbleData.targetId withDisplayName:nextBubbleData.targetDisplayName];
            }
            
            avatarPlaceholder = nextBubbleData.targetAvatarPlaceholder;
            avatarUrl = nextBubbleData.targetAvatarUrl;
        }
        else
        {
            // Use the Riot style placeholder
            if (!nextBubbleData.senderAvatarPlaceholder)
            {
                nextBubbleData.senderAvatarPlaceholder = [AvatarGenerator generateAvatarForMatrixItem:nextBubbleData.senderId withDisplayName:nextBubbleData.senderDisplayName];
            }
            
            avatarPlaceholder = nextBubbleData.senderAvatarPlaceholder;
            avatarUrl = nextBubbleData.senderAvatarUrl;
        }

        [avatarView setImageURI:avatarUrl
                       withType:nil
            andImageOrientation:UIImageOrientationUp
                  toFitViewSize:avatarView.frame.size
                     withMethod:MXThumbnailingMethodCrop
                   previewImage:avatarPlaceholder
                   mediaManager:nextBubbleData.mxSession.mediaManager];

        // Clear the default background color of a MXKImageView instance
        avatarView.defaultBackgroundColor = [UIColor clearColor];

        [self.avatarsView addSubview:avatarView];
    }
    while ((nextBubbleData = nextBubbleData.nextCollapsableCellData) && self.avatarsView.subviews.count < 5);
}

@end
