/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomTitleView.h"

@interface PreviewRoomTitleView : RoomTitleView

@property (weak, nonatomic) IBOutlet UIView *mainHeaderBackground;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainHeaderBackgroundHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *mainHeaderContainer;

@property (weak, nonatomic) IBOutlet MXKImageView *roomAvatar;
@property (weak, nonatomic) IBOutlet UITextView *roomTopic;
@property (weak, nonatomic) IBOutlet UILabel *roomMembers;
@property (weak, nonatomic) IBOutlet UIView *roomMembersDetailsIcon;

@property (weak, nonatomic) IBOutlet UILabel *previewLabel;
@property (weak, nonatomic) IBOutlet UIView *buttonsContainer;
@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;
@property (weak, nonatomic) IBOutlet UIButton *reportButton;
@property (weak, nonatomic) IBOutlet UILabel *subNoticeLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomBorderView;

@property (nonatomic) NSString *roomAvatarURL;
@property (nonatomic) UIImage  *roomAvatarPlaceholder;

@end
