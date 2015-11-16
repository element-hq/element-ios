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

#import <MatrixKit/MatrixKit.h>

@interface AuthInputsEmailIdentityBasedView : MXKAuthInputsView

/**
 The input text field used to fill an email.
 */
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;

/**
 The input text field used to fill the password.
 */
@property (weak, nonatomic) IBOutlet UITextField *passWordTextField;

@end
