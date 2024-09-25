/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

/**
 `DisabledRoomInputToolbarView` instance is an input toolbar to show to the end user
 that they have limited permission to interact with the room.
 */
@interface DisabledRoomInputToolbarView : MXKRoomInputToolbarView

@property (weak, nonatomic) IBOutlet UIView *mainToolbarView;

@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (strong, nonatomic) IBOutlet MXKImageView *pictureView;
@property (weak, nonatomic) IBOutlet UITextView *disabledReasonTextView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainToolbarMinHeightConstraint;

/**
 Display the limitation reason message.

 @param reason the reason why the user cannot interact with the room.
 */
- (void)setDisabledReason:(NSString*)reason;

@end
