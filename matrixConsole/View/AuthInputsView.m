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

#import "AuthInputsView.h"
#import "MatrixSDKHandler.h"

@implementation AuthInputsView

- (CGFloat)actualHeight {
    return self.frame.size.height;
}

- (BOOL)areAllRequiredFieldsFilled {
    // Currently no field to check here
    return YES;
}

- (void)setAuthType:(AuthenticationType)authType {
    if (authType == AuthenticationTypeLogin) {
        self.displayNameTextField.hidden = YES;
    } else {
        self.displayNameTextField.hidden = NO;
    }
    _authType = authType;
}

- (void)dismissKeyboard {
    [self.displayNameTextField resignFirstResponder];
}

- (void)nextStep {
    self.displayNameTextField.hidden = YES;
}

- (void)resetStep {
    self.authType = _authType;
}

@end

#pragma mark - AuthInputsPasswordBasedView

@implementation AuthInputsPasswordBasedView

- (CGFloat)actualHeight {
    if (self.authType == AuthenticationTypeLogin) {
        return self.displayNameTextField.frame.origin.y;
    }
    return super.actualHeight;
}

- (BOOL)areAllRequiredFieldsFilled {
    BOOL ret = [super areAllRequiredFieldsFilled];
    
    // Check user login and pass fields
    ret = (ret && self.userLoginTextField.text.length && self.passWordTextField.text.length);
    return ret;
}

- (void)setAuthType:(AuthenticationType)authType {
    if (authType == AuthenticationTypeLogin) {
        self.passWordTextField.returnKeyType = UIReturnKeyDone;
        self.emailTextField.hidden = YES;
        self.emailInfoLabel.hidden = YES;
    } else {
        self.passWordTextField.returnKeyType = UIReturnKeyNext;
        self.emailTextField.hidden = NO;
        self.emailInfoLabel.hidden = NO;
    }
    super.authType = authType;
    
    // Prefill text field
    self.userLoginTextField.text = [[MatrixSDKHandler sharedHandler] userLogin];
    self.passWordTextField.text = nil;
}

- (void)dismissKeyboard {
    [self.userLoginTextField resignFirstResponder];
    [self.passWordTextField resignFirstResponder];
    [self.emailTextField resignFirstResponder];
    
    [super dismissKeyboard];
}

#pragma mark UITextField delegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.userLoginTextField) {
        [[MatrixSDKHandler sharedHandler] setUserLogin:textField.text];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    if (textField.returnKeyType == UIReturnKeyDone) {
        // "Done" key has been pressed
        [textField resignFirstResponder];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(authInputsDoneKeyHasBeenPressed:)]) {
            // Launch authentication now
            [self.delegate authInputsDoneKeyHasBeenPressed:self];
        }
    } else {
        //"Next" key has been pressed
        if (textField == self.userLoginTextField) {
            [self.passWordTextField becomeFirstResponder];
        } else if (textField == self.passWordTextField) {
            [self.displayNameTextField becomeFirstResponder];
        } else if (textField == self.displayNameTextField) {
            [self.emailTextField becomeFirstResponder];
        }
    }
    
    return YES;
}
@end

#pragma mark - AuthInputsEmailCodeBasedView

@implementation AuthInputsEmailCodeBasedView

- (CGFloat)actualHeight {
    if (self.authType == AuthenticationTypeLogin) {
        return self.displayNameTextField.frame.origin.y;
    }
    return super.actualHeight;
}

- (BOOL)areAllRequiredFieldsFilled {
    BOOL ret = [super areAllRequiredFieldsFilled];
    
    // Check required fields //FIXME what are required fields in this authentication flow?
    ret = (ret && self.userLoginTextField.text.length && self.emailAndTokenTextField.text.length);
    return ret;
}

- (void)setAuthType:(AuthenticationType)authType {
    // Set initial layout
    self.userLoginTextField.hidden = NO;
    self.promptEmailTokenLabel.hidden = YES;
    
    if (authType == AuthenticationTypeLogin) {
        self.emailAndTokenTextField.returnKeyType = UIReturnKeyDone;
    } else {
        self.emailAndTokenTextField.returnKeyType = UIReturnKeyNext;
    }
    
    super.authType = authType;
}

- (void)dismissKeyboard {
    [self.userLoginTextField resignFirstResponder];
    [self.emailAndTokenTextField resignFirstResponder];
    
    [super dismissKeyboard];
}

- (void)nextStep {
    // Consider here the email token has been requested with success
    [super nextStep];
    
    self.userLoginTextField.hidden = YES;
    self.promptEmailTokenLabel.hidden = NO;
    self.emailAndTokenTextField.returnKeyType = UIReturnKeyDone;
}

#pragma mark UITextField delegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.userLoginTextField) {
        [[MatrixSDKHandler sharedHandler] setUserLogin:textField.text];
    }
    // FIXME store user's email in matrixSDKHandler like userId
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    if (textField.returnKeyType == UIReturnKeyDone) {
        // "Done" key has been pressed
        [textField resignFirstResponder];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(authInputsDoneKeyHasBeenPressed:)]) {
            // Launch authentication now
            [self.delegate authInputsDoneKeyHasBeenPressed:self];
        }
    } else {
        //"Next" key has been pressed
        if (textField == self.userLoginTextField) {
            [self.emailAndTokenTextField becomeFirstResponder];
        } else if (textField == self.emailAndTokenTextField) {
            [self.displayNameTextField becomeFirstResponder];
        }
    }
    
    return YES;
}

@end