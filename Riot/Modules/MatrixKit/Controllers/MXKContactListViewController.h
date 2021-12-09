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

#import <MatrixSDK/MatrixSDK.h>

#import "MXKTableViewController.h"

#import "MXKContactManager.h"
#import "MXKContact.h"
#import "MXKContactTableCell.h"

@class MXKContactListViewController;

/**
 `MXKContactListViewController` delegate.
 */
@protocol MXKContactListViewControllerDelegate <NSObject>

/**
 Tells the delegate that the user selected a contact.
 
 @param contactListViewController the `MXKContactListViewController` instance.
 @param contactId the id of the selected contact.
 */
- (void)contactListViewController:(MXKContactListViewController *)contactListViewController didSelectContact:(NSString*)contactId;

/**
 Tells the delegate that the user tapped a contact thumbnail.
 
 @param contactListViewController the `MXKContactListViewController` instance.
 @param contactId the id of the tapped contact.
 */
- (void)contactListViewController:(MXKContactListViewController *)contactListViewController didTapContactThumbnail:(NSString*)contactId;

@end

/**
 'MXKContactListViewController' instance displays constact list.
 This view controller support multi sessions by collecting all matrix users (only one occurrence is kept by user).
 */
@interface MXKContactListViewController : MXKTableViewController <UINavigationControllerDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate, MXKCellRenderingDelegate>

/**
 The segmented control used to handle separatly matrix users and local contacts.
 User's actions are handled by [MXKContactListViewController onSegmentValueChange:].
 */
@property (weak, nonatomic) IBOutlet UISegmentedControl* contactsControls;

/**
 The delegate for the view controller.
 */
@property (nonatomic, weak) id<MXKContactListViewControllerDelegate> delegate;

/**
 Enable the search option by adding a navigation item in the navigation bar (YES by default).
 Set NO this property to disable this option and hide the related bar button.
 */
@property (nonatomic) BOOL enableBarButtonSearch;

/**
 Tell whether an action is already in progress.
 */
@property (nonatomic, readonly) BOOL hasPendingAction;

/**
 The class used in creating new contact table cells.
 Only MXKContactTableCell classes or sub-classes are accepted.
 */
@property (nonatomic) Class contactTableViewCellClass;

#pragma mark - Class methods

/**
 Returns the `UINib` object initialized for a `MXKContactListViewController`.
 
 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 
 @discussion You may override this method to provide a customized nib. If you do,
 you should also override `contactListViewController` to return your
 view controller loaded from your custom nib.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `MXKContactListViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `MXKContactListViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)contactListViewController;

/**
 The action registered on 'value changed' event of the 'UISegmentedControl' contactControls.
 */
- (IBAction)onSegmentValueChange:(id)sender;

/**
 Add a mask in overlay to prevent a new contact selection (used when an action is on progress).
 */
- (void)addPendingActionMask;

/**
 Remove the potential overlay mask 
 */
- (void)removePendingActionMask;

@end

