/*
 Copyright 2016 OpenMarket Ltd
 
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

