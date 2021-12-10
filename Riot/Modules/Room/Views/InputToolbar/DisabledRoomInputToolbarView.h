/*
 Copyright 2018 New Vector Ltd

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
 `DisabledRoomInputToolbarView` instance is an input toolbar to show to the end user
 that they have limited permission to interact with the room.
 */
@interface DisabledRoomInputToolbarView : MXKRoomInputToolbarView

@property (weak, nonatomic) IBOutlet UIView *mainToolbarView;

@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (strong, nonatomic) IBOutlet MXKImageView *pictureView;
@property (weak, nonatomic) IBOutlet UITextView *disabledReasonTextView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainToolbarMinHeightConstraint;

/**
 Display the limitation reason message.

 @param reason the reason why the user cannot interact with the room.
 */
- (void)setDisabledReason:(NSString*)reason;

@end
