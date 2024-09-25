/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
*/

#import <UIKit/UIKit.h>

#import "MXKTableViewController.h"

#import "MXKAccountManager.h"

#import "MXK3PID.h"

/**
 */
typedef void (^blockMXKAccountDetailsViewController_onReadyToLeave)(void);

/**
 MXKAccountDetailsViewController instance may be used to display/edit the details of a matrix account.
 Only one matrix session is handled by this view controller.
 */
@interface MXKAccountDetailsViewController : MXKTableViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
@protected
    
    /**
     Section index
     */
    NSInteger linkedEmailsSection;
    NSInteger notificationsSection;
    NSInteger configurationSection;
    
    /**
     The logout button
     */
    UIButton *logoutButton;
    
    /**
     Linked email
     */
    MXK3PID  *submittedEmail;
    UIButton *emailSubmitButton;
    UITextField *emailTextField;

    // Notifications
    UISwitch *apnsNotificationsSwitch;
    UISwitch *inAppNotificationsSwitch;
    
    // The table cell with "Global Notification Settings" button
    UIButton *notificationSettingsButton;
}

/**
 The account displayed into the view controller.
 */
@property (nonatomic) MXKAccount *mxAccount;

/**
 The default account picture displayed when no picture is defined.
 */
@property (nonatomic) UIImage *picturePlaceholder;

@property (nonatomic, readonly) IBOutlet UIButton *userPictureButton;
@property (nonatomic, readonly) IBOutlet UITextField *userDisplayName;
@property (nonatomic, readonly) IBOutlet UIButton *saveUserInfoButton;

@property (nonatomic, readonly) IBOutlet UIView *profileActivityIndicatorBgView;
@property (nonatomic, readonly) IBOutlet UIActivityIndicatorView *profileActivityIndicator;

#pragma mark - Class methods

/**
 Returns the `UINib` object initialized for a `MXKAccountDetailsViewController`.

 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 
 @discussion You may override this method to provide a customized nib. If you do,
 you should also override `accountDetailsViewController` to return your
 view controller loaded from your custom nib.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `MXKAccountDetailsViewController` object.

 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `MXKAccountDetailsViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)accountDetailsViewController;

/**
 Action registered on the following events:
 - 'UIControlEventTouchUpInside' for each UIButton instance.
 - 'UIControlEventValueChanged' for each UISwitch instance.
 */
- (IBAction)onButtonPressed:(id)sender;

/**
 Action registered to handle text field edition
 */
- (IBAction)textFieldEditingChanged:(id)sender;

/**
 Prompt user to save potential changes before leaving the view controller.
 
 @param handler A block object called when the changes have been saved or discarded.
 
 @return YES if no change is observed. NO when the user is prompted.
 */
- (BOOL)shouldLeave:(blockMXKAccountDetailsViewController_onReadyToLeave)handler;

@end
