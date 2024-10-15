/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RecentTableViewCell.h"

/**
 Action identifier used when the user pressed 'preview' button displayed on room invitation.
 
 The `userInfo` dictionary contains an `MXRoom` object under the `kInviteRecentTableViewCellRoomKey` key, representing the room of the invitation.
 */
extern NSString *const kInviteRecentTableViewCellPreviewButtonPressed;

/**
 Action identifier used when the user pressed 'accept' button displayed on room invitation.
 
 The `userInfo` dictionary contains an `MXRoom` object under the `kInviteRecentTableViewCellRoomKey` key, representing the room of the invitation.
 */
extern NSString *const kInviteRecentTableViewCellAcceptButtonPressed;

/**
 Action identifier used when the user pressed 'decline' button displayed on room invitation.
 
 The `userInfo` dictionary contains an `MXRoom` object under the `kInviteRecentTableViewCellRoomKey` key, representing the room of the invitation.
 */
extern NSString *const kInviteRecentTableViewCellDeclineButtonPressed;

/**
 Notifications `userInfo` keys
 */
extern NSString *const kInviteRecentTableViewCellRoomKey;

/**
 `InviteRecentTableViewCell` instances display an invite to a room in the context of the recents list.
 */
@interface InviteRecentTableViewCell : RecentTableViewCell

@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *leftButtonActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *rightButtonActivityIndicator;

@end
