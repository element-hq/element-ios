/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd

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

/**
 The `RiotSearch` category adds the management of the search bar in Riot screens.
 */

#import <UIKit/UIKit.h>

@interface UIViewController (RiotSearch) <UISearchBarDelegate>

/**
 The search bar.
 */
@property (nonatomic, readonly) UISearchBar *searchBar;

/**
 The search bar state.
 */
@property (nonatomic, readonly) BOOL searchBarHidden;

/**
 The Riot empty search background image (champagne bubbles).
 The image adapts its width to its parent view width. 
 Its bottom is aligned to the top of the keyboard.
 */
@property (nonatomic, readonly) UIImageView *backgroundImageView;

@property (nonatomic, readonly) NSLayoutConstraint *backgroundImageViewBottomConstraint;

/**
 Show/Hide the search bar.

 @param animated or not.
 */
- (void)showSearch:(BOOL)animated;
- (void)hideSearch:(BOOL)animated;

/**
 Initialise `backgroundImageView` and add it to the passed parent view.
 
 @param view the view to add `backgroundImageView` to.
 */
- (void)addBackgroundImageViewToView:(UIView*)view;

/**
 Provide the new height of the keyboard to align `backgroundImageView`
 
 @param keyboardHeight the keyboard height.
 */
- (void)setKeyboardHeightForBackgroundImage:(CGFloat)keyboardHeight;

@end
