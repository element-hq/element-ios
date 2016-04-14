/*
 Copyright 2014 OpenMarket Ltd
 
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

#import "RoomTitleView.h"

#import "RoomEmailInvitation.h"

#import "UIViewController+VectorSearch.h"

@interface RoomViewController : MXKRoomViewController <UISearchBarDelegate, UIGestureRecognizerDelegate, RoomTitleViewTapGestureDelegate>

// The expanded header
@property (weak, nonatomic) IBOutlet UIView *expandedHeaderContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *expandedHeaderContainerHeightConstraint;

// The preview header
@property (weak, nonatomic) IBOutlet UIView *previewHeaderContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewHeaderContainerHeightConstraint;

/**
 Show/Hide the expanded header.
 By default this header is hidden on new instantiated RoomViewController object.
 */
- (void)showExpandedHeader:(BOOL)isVisible;

/**
 Display an invitation preview.
 
 @param emailInvitation the invitation received by email.
 */
- (void)displayEmailInvitation:(RoomEmailInvitation*)emailInvitation;

@end

