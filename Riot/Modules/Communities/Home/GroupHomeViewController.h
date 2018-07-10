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

@interface GroupHomeViewController : MXKViewController <UIGestureRecognizerDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *mainHeaderContainer;
@property (weak, nonatomic) IBOutlet MXKImageView *groupAvatar;
@property (weak, nonatomic) IBOutlet UIView *groupAvatarMask;
@property (weak, nonatomic) IBOutlet UILabel *groupName;
@property (weak, nonatomic) IBOutlet UIView *groupNameMask;
@property (weak, nonatomic) IBOutlet UILabel *groupDescription;
@property (weak, nonatomic) IBOutlet UIView *countsContainer;
@property (weak, nonatomic) IBOutlet UIView *membersCountContainer;
@property (weak, nonatomic) IBOutlet UIView *roomsCountContainer;
@property (weak, nonatomic) IBOutlet UILabel *membersCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *roomsCountLabel;

@property (weak, nonatomic) IBOutlet UIView *inviteContainer;
@property (weak, nonatomic) IBOutlet UILabel *inviteLabel;
@property (weak, nonatomic) IBOutlet UIView *buttonsContainer;
@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;

@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *separatorViewTopConstraint;

@property (weak, nonatomic) IBOutlet UITextView *groupLongDescription;

@property (strong, readonly, nonatomic) MXGroup *group;
@property (strong, readonly, nonatomic) MXSession *mxSession;

/**
 Returns the `UINib` object initialized for a `GroupHomeViewController`.
 
 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `GroupHomeViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `GroupHomeViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)groupHomeViewController;

/**
 Set the group for which the details are displayed.
 Provide the related matrix session.
 
 @param group
 @param mxSession
 */
- (void)setGroup:(MXGroup*)group withMatrixSession:(MXSession*)mxSession;

@end

