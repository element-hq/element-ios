/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

/**
 This title view display the room display name only.
 There is no user interaction in it except the back button.
 */
@interface SimpleRoomTitleView : MXKRoomTitleView <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *displayNameCenterXConstraint;

@end
