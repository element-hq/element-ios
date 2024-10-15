/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

@interface RoomAvatarTitleView : MXKRoomTitleView

@property (weak, nonatomic) IBOutlet UIView *roomAvatarMask;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *roomAvatarMaskCenterXConstraint;

@end
