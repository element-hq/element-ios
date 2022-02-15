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

