/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKViewControllerHandling.h"
#import "MXKActivityHandlingViewController.h"

/**
 MXKViewController extends UIViewController to handle requirements for
 any matrixKit view controllers (see MXKViewControllerHandling protocol).
 
 This class provides some methods to ease keyboard handling. 
 */

@interface MXKViewController : MXKActivityHandlingViewController <MXKViewControllerHandling>


#pragma mark - Keyboard handling

/**
 Call when keyboard display animation is complete.
 
 Override this method to set the actual keyboard view in 'keyboardView' property.
 The 'MXKViewController' instance will then observe the keyboard frame changes, and update 'keyboardHeight' property.
 */
- (void)onKeyboardShowAnimationComplete;

/**
 The current keyboard view (This field is nil when keyboard is dismissed).
 This property should be set when keyboard display animation is complete to track keyboard frame changes.
 */
@property (nonatomic) UIView *keyboardView;

/**
 The current keyboard height (This field is 0 when keyboard is dismissed).
 */
@property CGFloat keyboardHeight;

@end

