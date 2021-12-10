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

#import "MXKAuthInputsView.h"

@interface MXKAuthInputsPasswordBasedView : MXKAuthInputsView

/**
 The input text field related to user id or user login.
 */
@property (weak, nonatomic) IBOutlet UITextField *userLoginTextField;

/**
 The input text field used to fill the password.
 */
@property (weak, nonatomic) IBOutlet UITextField *passWordTextField;

/**
 The input text field used to fill an email. This item is optional, it is added in case of registration.
 */
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;

/**
 Label used to display email field information.
 */
@property (weak, nonatomic) IBOutlet UILabel *emailInfoLabel;

/**
 The text field related to the display name. This item is displayed in case of registration.
 */
@property (weak, nonatomic) IBOutlet UITextField *displayNameTextField;

@end
