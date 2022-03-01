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
