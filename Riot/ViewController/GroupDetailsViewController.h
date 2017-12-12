/*
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

#import <MatrixKit/MatrixKit.h>

@interface GroupDetailsViewController : MXKViewController <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *groupAvatarHeaderBackground;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *groupAvatarHeaderBackgroundHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet MXKImageView *groupAvatar;
@property (weak, nonatomic) IBOutlet UIView *groupAvatarMask;
@property (weak, nonatomic) IBOutlet UILabel *groupNameLabel;
@property (weak, nonatomic) IBOutlet UIView *groupNameLabelMask;

@property (weak, nonatomic) IBOutlet UILabel *groupDescriptionLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

/**
 The displayed group
 */
@property (nonatomic) MXGroup *group;

/**
 Returns the `UINib` object initialized for a `GroupDetailsViewController`.
 
 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `GroupDetailsViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `GroupDetailsViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)groupDetailsViewController;

@end

