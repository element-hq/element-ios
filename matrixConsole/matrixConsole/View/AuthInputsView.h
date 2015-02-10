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

#import <UIKit/UIKit.h>

// Authentication type: register or login
typedef enum {
    AuthenticationTypeRegister,
    AuthenticationTypeLogin
}
AuthenticationType;

@class AuthInputsView;

@protocol AuthInputsViewDelegate <NSObject>
@optional
- (void)authInputsDoneKeyHasBeenPressed:(AuthInputsView *)authInputsView;
@end

@interface AuthInputsView : UIView <UITextFieldDelegate>

@property (nonatomic) AuthenticationType authType;
@property (nonatomic) id <AuthInputsViewDelegate> delegate;
// Optional fields added in case of registration
@property (weak, nonatomic) IBOutlet UITextField *displayNameTextField;

- (CGFloat)actualHeight;
- (BOOL)areAllRequiredFieldsFilled;
- (void)dismissKeyboard;

- (void)nextStep;
- (void)resetStep;
@end

@interface AuthInputsPasswordBasedView : AuthInputsView
@property (weak, nonatomic) IBOutlet UITextField *userLoginTextField;
@property (weak, nonatomic) IBOutlet UITextField *passWordTextField;
// Optional fields added in case of registration
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UILabel *emailInfoLabel;
@end

@interface AuthInputsEmailCodeBasedView : AuthInputsView
@property (weak, nonatomic) IBOutlet UITextField *userLoginTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailAndTokenTextField;
@property (weak, nonatomic) IBOutlet UILabel *promptEmailTokenLabel;
@end
