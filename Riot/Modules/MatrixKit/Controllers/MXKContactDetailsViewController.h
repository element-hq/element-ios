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

#import <UIKit/UIKit.h>

#import "MXKTableViewController.h"

#import "MXKContact.h"

@class MXKContactDetailsViewController;

/**
 `MXKContactDetailsViewController` delegate.
 */
@protocol MXKContactDetailsViewControllerDelegate <NSObject>

/**
 Tells the delegate that the user wants to start chat with the contact by using the selected matrix id.
 
 @param contactDetailsViewController the `MXKContactDetailsViewController` instance.
 @param matrixId the selected matrix id of the contact.
 @param completion the block to execute at the end of the operation (independently if it succeeded or not).
 */
- (void)contactDetailsViewController:(MXKContactDetailsViewController *)contactDetailsViewController startChatWithMatrixId:(NSString*)matrixId completion:(void (^)(void))completion;

@end

@interface MXKContactDetailsViewController : MXKTableViewController

@property (weak, nonatomic) IBOutlet UIButton *contactThumbnail;
@property (weak, nonatomic) IBOutlet UITextView *contactDisplayName;

/**
 The default account picture displayed when no picture is defined.
 */
@property (nonatomic) UIImage *picturePlaceholder;

/**
 The displayed contact
 */
@property (strong, nonatomic) MXKContact* contact;

/**
 The delegate for the view controller.
 */
@property (nonatomic, weak) id<MXKContactDetailsViewControllerDelegate> delegate;

#pragma mark - Class methods

/**
 Returns the `UINib` object initialized for a `MXKContactDetailsViewController`.
 
 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 
 @discussion You may override this method to provide a customized nib. If you do,
 you should also override `contactDetailsViewController` to return your
 view controller loaded from your custom nib.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `MXKContactDetailsViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `MXKContactDetailsViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)contactDetailsViewController;

/**
 The contact's thumbnail is displayed inside a button. The following action is registered on
 `UIControlEventTouchUpInside` event of this button.
 */
- (IBAction)onContactThumbnailPressed:(id)sender;

@end

