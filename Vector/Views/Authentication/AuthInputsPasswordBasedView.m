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

#import "AuthInputsPasswordBasedView.h"

#import "NSBundle+MatrixKit.h"

#import "VectorDesignValues.h"

@implementation AuthInputsPasswordBasedView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self)
                          bundle:[NSBundle bundleForClass:self]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _repeatPasswordTextField.placeholder = NSLocalizedStringFromTable(@"auth_repeat_password_placeholder", @"Vector", nil);
    _repeatPasswordTextField.textColor = VECTOR_TEXT_GRAY_COLOR;
    
    self.userLoginTextField.placeholder = NSLocalizedStringFromTable(@"auth_user_id_placeholder", @"Vector", nil);
    self.userLoginTextField.textColor = VECTOR_TEXT_GRAY_COLOR;
    
    self.passWordTextField.placeholder = NSLocalizedStringFromTable(@"auth_password_placeholder", @"Vector", nil);
    self.passWordTextField.textColor = VECTOR_TEXT_GRAY_COLOR;
    
    self.emailTextField.placeholder = NSLocalizedStringFromTable(@"auth_email_placeholder", @"Vector", nil);
    self.emailTextField.textColor = VECTOR_TEXT_GRAY_COLOR;
}

- (CGFloat)actualHeight
{
    return self.viewHeightConstraint.constant;
}

- (BOOL)areAllRequiredFieldsFilled
{
    if (self.authType == MXKAuthenticationTypeLogin)
    {
        return (self.userLoginTextField.text.length && self.passWordTextField.text.length);
    }
    
    return (self.userLoginTextField.text.length && self.emailTextField.text.length && self.passWordTextField.text.length && self.repeatPasswordTextField.text.length);
}

- (void)setAuthType:(MXKAuthenticationType)authType
{
    super.authType = authType;
    
    if (authType == MXKAuthenticationTypeLogin)
    {
        self.userLoginTextField.placeholder = NSLocalizedStringFromTable(@"auth_user_id_placeholder", @"Vector", nil);
        
        self.passwordContainerTopConstraint.constant = 50;
        
        self.emailContainer.hidden = YES;
        self.repeatPasswordContainer.hidden = YES;
    }
    else
    {
        self.userLoginTextField.placeholder = NSLocalizedStringFromTable(@"auth_user_name_placeholder", @"Vector", nil);
        
        self.passwordContainerTopConstraint.constant = 100;
        
        self.emailContainer.hidden = NO;
        self.repeatPasswordContainer.hidden = NO;
    }
}

- (void)dismissKeyboard
{
    [self.userLoginTextField resignFirstResponder];
    [self.passWordTextField resignFirstResponder];
    [self.emailTextField resignFirstResponder];
    [self.repeatPasswordTextField resignFirstResponder];
}

#pragma mark UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    if (textField.returnKeyType == UIReturnKeyDone)
    {
        // "Done" key has been pressed
        [textField resignFirstResponder];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(authInputsDoneKeyHasBeenPressed:)])
        {
            // Launch authentication now
            [self.delegate authInputsDoneKeyHasBeenPressed:self];
        }
    }
    else
    {
        //"Next" key has been pressed
        if (textField == self.userLoginTextField)
        {
            if (self.emailContainer.isHidden)
            {
                [self.passWordTextField becomeFirstResponder];
            }
            else
            {
                [self.emailTextField becomeFirstResponder];
            }
        }
        else if (textField == self.emailTextField)
        {
            [self.passwordContainer becomeFirstResponder];
        }
        else if (textField == self.passWordTextField)
        {
            [self.repeatPasswordTextField becomeFirstResponder];
        }
    }
    
    return YES;
}
@end
