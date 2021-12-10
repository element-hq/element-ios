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

#import <MatrixSDK/MatrixSDK.h>

#import "UIViewController+RiotSearch.h"
#import "MatrixKit.h"

/**
 This view controller manages several uiviewcontrollers like UISegmentedController manages uiTableView
 except that the managed items are custom UIViewControllers.
 It uses a Vector design.
 */
@interface SegmentedViewController : MXKViewController

#pragma mark - Class methods
@property (weak, nonatomic) IBOutlet UIView *selectionContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *selectionContainerTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *selectionContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *viewControllerContainer;

/**
 The index of the view controller that currently has the focus.
 */
@property (nonatomic) NSUInteger selectedIndex;

/**
 The tint color for the section header (ThemeService.shared.theme.accent by default).
 */
@property (nonatomic) UIColor *sectionHeaderTintColor;

/**
 The view controller that currently has the focus.
 */
@property (nonatomic, readonly) UIViewController *selectedViewController;

/**
 The view controllers managed by this SegmentedViewController instance.
 */
@property (nonatomic, readonly) NSArray<UIViewController*> *viewControllers;

/**
 Returns the `UINib` object initialized for a `SegmentedViewController`.

 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 
 @discussion You may override this method to provide a customized nib. If you do,
 you should also override `SegmentedViewController` to return your
 view controller loaded from your custom nib.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `SegmentedViewController` object.

 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `SegmentedViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)segmentedViewController;

/**
 init the segmentedViewController with a list of UIViewControllers.
 The subviewcontrollers must implement didMoveToParentViewController to display the navbar button.
 
 @discussion: the segmentedViewController gets the ownership of the provided arrays and their content.
 
 @param titles the section tiles
 @param viewControllers the list of viewControllers to display.
 @param defaultSelected index of the default selected UIViewController in the list.
 */
- (void)initWithTitles:(NSArray*)titles viewControllers:(NSArray*)viewControllers defaultSelected:(NSUInteger)defaultSelected;

/**
 Callback used to take into account the change of the user interface theme.
 */
- (void)userInterfaceThemeDidChange;

@end
