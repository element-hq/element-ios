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

#import "AuthInputsEmailIdentityBasedView.h"

@implementation AuthInputsEmailIdentityBasedView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([AuthInputsEmailIdentityBasedView class])
                          bundle:[NSBundle bundleForClass:[AuthInputsEmailIdentityBasedView class]]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _emailTextField.placeholder = NSLocalizedStringFromTable(@"auth_email_placeholder", @"Vector", nil);
    _passWordTextField.placeholder = NSLocalizedStringFromTable(@"auth_password_placeholder", @"Vector", nil);
    
    self.passWordTextField.returnKeyType = UIReturnKeyDone;
}

- (BOOL)areAllRequiredFieldsFilled
{
    BOOL ret = [super areAllRequiredFieldsFilled];
    
    // Check user email and pass fields
    ret = (ret && self.emailTextField.text.length && self.passWordTextField.text.length);
    return ret;
}

- (void)dismissKeyboard
{
    [self.passWordTextField resignFirstResponder];
    [self.emailTextField resignFirstResponder];
    
    [super dismissKeyboard];
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
        if (textField == self.emailTextField)
        {
            [self.passWordTextField becomeFirstResponder];
        }
    }
    
    return YES;
}
@end
