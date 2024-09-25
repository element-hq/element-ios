/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomTitleView.h"

@interface ExpandedRoomTitleView : RoomTitleView

@property (weak, nonatomic) IBOutlet MXKImageView *roomAvatar;
@property (weak, nonatomic) IBOutlet UIImageView *roomAvatarBadgeImageView;
@property (weak, nonatomic) IBOutlet UIView *roomAvatarHeaderBackground;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *roomAvatarHeaderBackgroundHeightConstraint;

@property (weak, nonatomic) IBOutlet UILabel *roomTopic;
@property (weak, nonatomic) IBOutlet UILabel *roomMembers;

@property (weak, nonatomic) IBOutlet UIView *bottomBorderView;

@property (weak, nonatomic) IBOutlet UIImageView *membersListIcon;
@property (weak, nonatomic) IBOutlet UIImageView *addParticipantIcon;

@end
