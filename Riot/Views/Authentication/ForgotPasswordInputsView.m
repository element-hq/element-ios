/*
 Copyright 2016 OpenMarket Ltd
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

#import "ForgotPasswordInputsView.h"

#import "VectorDesignValues.h"

@interface ForgotPasswordInputsView ()
{
    /**
     The current email validation
     */
    MXK3PID  *submittedEmail;
    
    /**
     The current set of parameters ready to use.
     */
    NSDictionary *parameters;
    
    /**
     The block called when the parameters are ready and the user confirms he has checked his email.
     */
    void (^didPrepareParametersCallback)(NSDictionary *parameters);
}

@end

@implementation ForgotPasswordInputsView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self)
                          bundle:[NSBundle bundleForClass:self]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.emailTextField.placeholder = NSLocalizedStringFromTable(@"auth_email_placeholder", @"Vector", nil);
    self.emailTextField.textColor = kVectorTextColorBlack;
    
    self.passWordTextField.placeholder = NSLocalizedStringFromTable(@"auth_new_password_placeholder", @"Vector", nil);
    self.passWordTextField.textColor = kVectorTextColorBlack;
    
    self.repeatPasswordTextField.placeholder = NSLocalizedStringFromTable(@"auth_repeat_new_password_placeholder", @"Vector", nil);
    self.repeatPasswordTextField.textColor = kVectorTextColorBlack;
    
    self.messageLabel.numberOfLines = 0;
    
    [self.nextStepButton.layer setCornerRadius:5];
    self.nextStepButton.clipsToBounds = YES;
    self.nextStepButton.backgroundColor = kVectorColorGreen;
    [self.nextStepButton setTitle:[NSBundle mxk_localizedStringForKey:@"auth_reset_password_next_step_button"] forState:UIControlStateNormal];
    [self.nextStepButton setTitle:[NSBundle mxk_localizedStringForKey:@"auth_reset_password_next_step_button"] forState:UIControlStateHighlighted];
    self.nextStepButton.enabled = YES;
}

- (void)destroy
{
    [super destroy];
    
    submittedEmail = nil;
    
    parameters = nil;
    didPrepareParametersCallback = nil;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect lastItemFrame;
    
    if (!self.repeatPasswordContainer.isHidden)
    {
        lastItemFrame = self.repeatPasswordContainer.frame;
    }
    else if (!self.nextStepButton.isHidden)
    {
        lastItemFrame = self.nextStepButton.frame;
    }
    else
    {
        lastItemFrame = self.messageLabel.frame;
    }
    
    self.viewHeightConstraint.constant = lastItemFrame.origin.y + lastItemFrame.size.height;
}

#pragma mark -

- (BOOL)setAuthSession:(MXAuthenticationSession *)authSession withAuthType:(MXKAuthenticationType)authType;
{
    if (authType == MXKAuthenticationTypeForgotPassword)
    {
        type = MXKAuthenticationTypeForgotPassword;
        
        // authSession is not used here, filled it by default (it should be nil).
        currentSession = authSession;
        
        // Reset UI in initial step
        [self reset];
        
        return YES;
    }
    
    return NO;
}

- (NSString*)validateParameters
{
    // Check the validity of the parameters
    NSString *errorMsg = nil;
    
    if (!self.emailTextField.text.length)
    {
        NSLog(@"[ForgotPasswordInputsView] Missing email");
        errorMsg = NSLocalizedStringFromTable(@"auth_reset_password_missing_email", @"Vector", nil);
    }
    else if (!self.passWordTextField.text.length)
    {
        NSLog(@"[ForgotPasswordInputsView] Missing Passwords");
        errorMsg = NSLocalizedStringFromTable(@"auth_reset_password_missing_password", @"Vector", nil);
    }
    else if (self.passWordTextField.text.length < 6)
    {
        NSLog(@"[ForgotPasswordInputsView] Invalid Passwords");
        errorMsg = NSLocalizedStringFromTable(@"auth_invalid_password", @"Vector", nil);
    }
    else if ([self.repeatPasswordTextField.text isEqualToString:self.passWordTextField.text] == NO)
    {
        NSLog(@"[ForgotPasswordInputsView] Passwords don't match");
        errorMsg = NSLocalizedStringFromTable(@"auth_password_dont_match", @"Vector", nil);
    }
    else
    {
        // Check validity of the non empty email
        if ([MXTools isEmailAddress:self.emailTextField.text] == NO)
        {
            NSLog(@"[ForgotPasswordInputsView] Invalid email");
            errorMsg = NSLocalizedStringFromTable(@"auth_invalid_email", @"Vector", nil);
        }
    }
    
    return errorMsg;
}

- (void)prepareParameters:(void (^)(NSDictionary *parameters))callback
{
    if (callback)
    {
        // Prepare here parameters dict by checking each required fields.
        parameters = nil;
        didPrepareParametersCallback = nil;
        
        // Check the validity of the parameters
        NSString *errorMsg = [self validateParameters];
        if (errorMsg)
        {
            if (inputsAlert)
            {
                [inputsAlert dismiss:NO];
            }
            
            inputsAlert = [[MXKAlert alloc] initWithTitle:[NSBundle mxk_localizedStringForKey:@"error"] message:errorMsg style:MXKAlertStyleAlert];
            inputsAlert.cancelButtonIndex = [inputsAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                inputsAlert = nil;
            }];
            
            [self.delegate authInputsView:self presentMXKAlert:inputsAlert];
        }
        else
        {
            // Retrieve the REST client from delegate
            MXRestClient *restClient;
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(authInputsViewThirdPartyIdValidationRestClient:)])
            {
                restClient = [self.delegate authInputsViewThirdPartyIdValidationRestClient:self];
            }
            
            if (restClient)
            {
                // Launch email validation
                submittedEmail = [[MXK3PID alloc] initWithMedium:kMX3PIDMediumEmail andAddress:self.emailTextField.text];
                
                [submittedEmail requestValidationTokenWithMatrixRestClient:restClient
                                                                  nextLink:nil
                                                                   success:^{
                                                                       
                                                                       didPrepareParametersCallback = callback;
                                                                       
                                                                       NSURL *identServerURL = [NSURL URLWithString:restClient.identityServer];
                                                                       parameters = @{
                                                                                      @"auth": @{@"threepid_creds": @{@"client_secret": submittedEmail.clientSecret, @"id_server": identServerURL.host, @"sid": submittedEmail.sid}, @"type": kMXLoginFlowTypeEmailIdentity},
                                                                                      @"new_password": self.passWordTextField.text};
                                                                       
                                                                       [self hideInputsContainer];
                                                                       
                                                                       self.messageLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"auth_reset_password_email_validation_message", @"Vector", nil), self.emailTextField.text];
                                                                       
                                                                       self.messageLabel.hidden = NO;
                                                                       
                                                                       [self.nextStepButton addTarget:self action:@selector(didCheckEmail:) forControlEvents:UIControlEventTouchUpInside];
                                                                       
                                                                       self.nextStepButton.hidden = NO;
                                                                       
                                                                   } failure:^(NSError *error) {
                                                                       
                                                                       NSLog(@"[ForgotPasswordInputsView] Failed to request email token");
                                                                       
                                                                       // Ignore connection cancellation error
                                                                       if (([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled))
                                                                       {
                                                                           return;
                                                                       }
                                                                       
                                                                       callback(nil);
                                                                       
                                                                   }];
                
                // Async response
                return;
            }
            else
            {
                NSLog(@"[ForgotPasswordInputsView] Operation failed during the email identity stage");
            }
        }
        
        callback(parameters);
    }
}

- (BOOL)areAllRequiredFieldsSet
{
    // Keep enable the submit button.
    return YES;
}

- (void)dismissKeyboard
{
    [self.passWordTextField resignFirstResponder];
    [self.emailTextField resignFirstResponder];
    [self.repeatPasswordTextField resignFirstResponder];
    
    [super dismissKeyboard];
}

- (NSString*)password
{
    return self.passWordTextField.text;
}

- (void)nextStep
{
    // Here the password has been reseted with success
    didPrepareParametersCallback = nil;
    parameters = nil;
    
    [self hideInputsContainer];
    
    self.messageLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"auth_reset_password_success_message", @"Vector", nil), self.emailTextField.text];
    
    self.messageLabel.hidden = NO;
}

#pragma mark - Internals

- (void)reset
{
    // Cancel email validation if any
    if (submittedEmail)
    {
        [submittedEmail cancelCurrentRequest];
        submittedEmail = nil;
    }
    
    parameters = nil;
    didPrepareParametersCallback = nil;
    
    // Reset UI by hidding all items
    [self hideInputsContainer];
    
    self.messageLabel.text = NSLocalizedStringFromTable(@"auth_reset_password_message", @"Vector", nil);
    self.messageLabel.hidden = NO;
    
    self.emailContainer.hidden = NO;
    self.passwordContainer.hidden = NO;
    self.repeatPasswordContainer.hidden = NO;
    
    [self layoutIfNeeded];
}

#pragma mark - actions

- (void)didCheckEmail:(id)sender
{
    if (sender == self.nextStepButton)
    {
        if (didPrepareParametersCallback)
        {
            didPrepareParametersCallback(parameters);
        }
    }
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    if (textField.returnKeyType == UIReturnKeyDone)
    {
        // "Done" key has been pressed
        [textField resignFirstResponder];
        
        // Launch authentication now
        [self.delegate authInputsViewDidPressDoneKey:self];
    }
    else
    {
        //"Next" key has been pressed
        if (textField == self.emailTextField)
        {
            [self.passWordTextField becomeFirstResponder];
        }
        else if (textField == self.passWordTextField)
        {
            [self.repeatPasswordTextField becomeFirstResponder];
        }
    }
    
    return YES;
}

#pragma mark -

- (void)hideInputsContainer
{
    // Hide all inputs container
    self.passwordContainer.hidden = YES;
    self.emailContainer.hidden = YES;
    self.repeatPasswordContainer.hidden = YES;
    
    // Hide other items
    self.messageLabel.hidden = YES;
    self.nextStepButton.hidden = YES;
}

@end
