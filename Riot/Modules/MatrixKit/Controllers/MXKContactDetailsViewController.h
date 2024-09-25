/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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

