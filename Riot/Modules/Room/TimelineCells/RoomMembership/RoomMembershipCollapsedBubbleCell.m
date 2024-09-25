/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomMembershipCollapsedBubbleCell.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#import "RoomBubbleCellData.h"

#import "AvatarGenerator.h"

@implementation RoomMembershipCollapsedBubbleCell

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
