/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

@class PresenceIndicatorView;

/**
 `RecentTableViewCell` instances display a room in the context of the recents list.
 */
@interface RecentTableViewCell : MXKRecentTableViewCell

@property (weak, nonatomic) IBOutlet UIView *missedNotifAndUnreadIndicator;
@property (weak, nonatomic) IBOutlet MXKImageView *roomAvatar;
@property (weak, nonatomic) IBOutlet UIImageView *encryptedRoomIcon;
@property (weak, nonatomic) IBOutlet PresenceIndicatorView *presenceIndicatorView;

@property (weak, nonatomic) IBOutlet UILabel *missedNotifAndUnreadBadgeLabel;
@property (weak, nonatomic) IBOutlet UIView  *missedNotifAndUnreadBadgeBgView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *missedNotifAndUnreadBadgeBgViewWidthConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lastEventDecriptionLabelTrailingConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *unsentImageView;

@end
