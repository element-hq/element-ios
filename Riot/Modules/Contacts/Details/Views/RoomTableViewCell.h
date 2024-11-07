/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

/**
 The `RoomTableViewCell` cell displays a room (avatar and displayname).
 */
@interface RoomTableViewCell : MXKTableViewCell

@property (weak, nonatomic) IBOutlet MXKImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *encryptedRoomIcon;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

/**
 Update the information displayed by the cell.
 
 @param room the room to render.
 */
- (void)render:(MXRoom *)room;

/**
 Get the cell height.

 @return the cell height.
 */
+ (CGFloat)cellHeight;

@end
