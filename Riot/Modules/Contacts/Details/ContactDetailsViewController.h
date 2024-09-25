/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

/**
 Available actions on contact
 */
typedef enum : NSUInteger
{
    ContactDetailsActionIgnore,
    ContactDetailsActionUnignore,
    ContactDetailsActionStartChat,
    ContactDetailsActionStartVoiceCall,
    ContactDetailsActionStartVideoCall
} ContactDetailsAction;

@interface ContactDetailsViewController : MXKViewController <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *contactAvatarHeaderBackground;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contactAvatarHeaderBackgroundHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet MXKImageView *contactAvatar;
@property (weak, nonatomic) IBOutlet UIView *contactAvatarMask;
@property (weak, nonatomic) IBOutlet UILabel *contactNameLabel;
@property (weak, nonatomic) IBOutlet UIView *contactNameLabelMask;

@property (weak, nonatomic) IBOutlet UILabel *contactStatusLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIImageView *bottomImageView;

/**
 The displayed contact
 */
@property (nonatomic) MXKContact *contact;

/**
 Enable voip call (voice/video). NO by default
 */
@property (nonatomic) BOOL enableVoipCall;

/**
 Returns the `UINib` object initialized for a `ContactDetailsViewController`.
 
 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `ContactDetailsViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `ContactDetailsViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)instantiate;

@end

