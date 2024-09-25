/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomInputToolbarView.h"

/**
 `MXKRoomInputToolbarViewWithSimpleTextView` is a MXKRoomInputToolbarView-inherited class in which message
 composer is a UITextView instance with a fixed heigth.
 
 Toolbar buttons are not overridden by this class. We keep the default implementation.
 */
@interface MXKRoomInputToolbarViewWithSimpleTextView : MXKRoomInputToolbarView <UITextViewDelegate>

/**
  Message composer defined in `messageComposerContainer`.
 */
@property (weak, nonatomic) IBOutlet UITextView *messageComposerTextView;

@end
