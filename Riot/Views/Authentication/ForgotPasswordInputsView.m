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

#import "MXHTTPOperation.h"
#import "RiotDesignValues.h"

@interface ForgotPasswordInputsView ()

/**
 The current email validation request operation
 */
@property (nonatomic, strong) MXHTTPOperation *mxCurrentOperation;

/**
 The current set of parameters ready to use.
 */
@property (nonatomic, strong) NSDictionary *parameters;

/**
 The block called when the parameters are ready and the user confirms he has checked his email.
 */
@property (nonatomic, copy) void (^didPrepareParametersCallback)(NSDictionary *parameters, NSError *error);

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
    
    [self.nextStepButton setTitle:[NSBundle mxk_localizedStringForKey:@"auth_reset_password_next_step_button"] forState:UIControlStateNormal];
    [self.nextStepButton setTitle:[NSBundle mxk_localizedStringForKey:@"auth_reset_password_next_step_button"] forState:UIControlStateHighlighted];
    self.nextStepButton.enabled = YES;
    
    self.emailTextField.placeholder = NSLocalizedStringFromTable(@"auth_email_placeholder", @"Vector", nil);
    self.passWordTextField.placeholder = NSLocalizedStringFromTable(@"auth_new_password_placeholder", @"Vector", nil);
    self.repeatPasswordTextField.placeholder = NSLocalizedStringFromTable(@"auth_repeat_new_password_placeholder", @"Vector", nil);
    
    if (kRiotPlaceholderTextColor)
    {
        // Apply placeholder color
        [self customizeViewRendering];
    }    
}

- (void)destroy
{
    [super destroy];
    
    self.mxCurrentOperation = nil;
    
    self.parameters = nil;
    self.didPrepareParametersCallback = nil;
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

#pragma mark - Override MXKView

-(void)customizeViewRendering
{
    [super customizeViewRendering];
    
    self.messageLabel.textColor = kRiotPrimaryTextColor;
    
    self.emailTextField.textColor = kRiotPrimaryTextColor;
    self.passWordTextField.textColor = kRiotPrimaryTextColor;
    self.repeatPasswordTextField.textColor = kRiotPrimaryTextColor;
    
    self.messageLabel.numberOfLines = 0;
    
    [self.nextStepButton.layer setCornerRadius:5];
    self.nextStepButton.clipsToBounds = YES;
    self.nextStepButton.backgroundColor = kRiotColorGreen;
    
    if (kRiotPlaceholderTextColor)
    {
        if (self.emailTextField.placeholder)
        {
            self.emailTextField.attributedPlaceholder = [[NSAttributedString alloc]
                                                         initWithString:self.emailTextField.placeholder
                                                         attributes:@{NSForegroundColorAttributeName: kRiotPlaceholderTextColor}];
        }
        if (self.passWordTextField.placeholder)
        {
            self.passWordTextField.attributedPlaceholder = [[NSAttributedString alloc]
                                                         initWithString:self.passWordTextField.placeholder
                                                         attributes:@{NSForegroundColorAttributeName: kRiotPlaceholderTextColor}];
        }
        if (self.repeatPasswordTextField.placeholder)
        {
            self.repeatPasswordTextField.attributedPlaceholder = [[NSAttributedString alloc]
                                                            initWithString:self.repeatPasswordTextField.placeholder
                                                            attributes:@{NSForegroundColorAttributeName: kRiotPlaceholderTextColor}];
        }
    }
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

- (void)prepareParameters:(void (^)(NSDictionary *parameters, NSError *error))callback
{
    if (callback)
    {
        // Prepare here parameters dict by checking each required fields.
        self.parameters = nil;
        self.didPrepareParametersCallback = nil;
        
        // Check the validity of the parameters
        NSString *errorMsg = [self validateParameters];
        if (errorMsg)
        {
            if (inputsAlert)
            {
                [inputsAlert dismissViewControllerAnimated:NO completion:nil];
            }
            
            inputsAlert = [UIAlertController alertControllerWithTitle:[NSBundle mxk_localizedStringForKey:@"error"] message:errorMsg preferredStyle:UIAlertControllerStyleAlert];
            
            [inputsAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                              inputsAlert = nil;
                                                              
                                                          }]];
            
            [self.delegate authInputsView:self presentAlertController:inputsAlert];
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
                NSString *clientSecret = [MXTools generateSecret];
                
                __weak typeof(self) weakSelf = self;
                [restClient forgetPasswordForEmail:self.emailTextField.text
                                      clientSecret:clientSecret
                                       sendAttempt:1
                                           success:^(NSString *sid)
                 {
                     typeof(weakSelf) strongSelf = weakSelf;
                     if (strongSelf) {
                         strongSelf.didPrepareParametersCallback = callback;
                         
                         NSURL *identServerURL = [NSURL URLWithString:restClient.identityServer];
                         strongSelf.parameters = @{
                                                   @"auth": @{
                                                           @"threepid_creds": @{
                                                                   @"client_secret": clientSecret,
                                                                   @"id_server": identServerURL.host,
                                                                   @"sid": sid
                                                                   },
                                                           @"type": kMXLoginFlowTypeEmailIdentity
                                                           },
                                                   @"new_password": strongSelf.passWordTextField.text
                                                   };
                         
                         [strongSelf hideInputsContainer];
                         
                         strongSelf.messageLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"auth_reset_password_email_validation_message", @"Vector", nil), strongSelf.emailTextField.text];
                         
                         strongSelf.messageLabel.hidden = NO;
                         
                         [strongSelf.nextStepButton addTarget:strongSelf
                                                       action:@selector(didCheckEmail:)
                                             forControlEvents:UIControlEventTouchUpInside];
                         
                         strongSelf.nextStepButton.hidden = NO;
                     }
                 }
                                           failure:^(NSError *error)
                 {
                     NSLog(@"[ForgotPasswordInputsView] Failed to request email token");
                     
                     // Ignore connection cancellation error
                     if (([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled))
                     {
                         return;
                     }
                     
                     NSString *errorMessage;
                     
                     // Translate the potential MX error.
                     MXError *mxError = [[MXError alloc] initWithNSError:error];
                     if (mxError && [mxError.errcode isEqualToString:kMXErrCodeStringThreePIDNotFound])
                         errorMessage = NSLocalizedStringFromTable(@"auth_email_not_found", @"Vector", nil);
                     else if (mxError && [mxError.errcode isEqualToString:kMXErrCodeStringServerNotTrusted])
                         errorMessage = NSLocalizedStringFromTable(@"auth_untrusted_id_server", @"Vector", nil);
                     else if (error.userInfo[@"error"])
                         errorMessage = error.userInfo[@"error"];
                     else
                         errorMessage = error.localizedDescription;
                     
                     if (weakSelf)
                     {
                         typeof(self) self = weakSelf;
                         
                         if (self->inputsAlert)
                         {
                             [self->inputsAlert dismissViewControllerAnimated:NO completion:nil];
                         }
                         
                         self->inputsAlert = [UIAlertController alertControllerWithTitle:[NSBundle mxk_localizedStringForKey:@"error"] message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
                         
                         [self->inputsAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                                               style:UIAlertActionStyleDefault
                                                                             handler:^(UIAlertAction * action) {
                                                                                 
                                                                                 if (weakSelf)
                                                                                 {
                                                                                     typeof(self) self = weakSelf;
                                                                                     self->inputsAlert = nil;
                                                                                     if (self.delegate && [self.delegate respondsToSelector:@selector(authInputsViewDidCancelOperation:)])
                                                                                     {
                                                                                         [self.delegate authInputsViewDidCancelOperation:self];
                                                                                     }
                                                                                 }
                                                                                 
                                                                             }]];
                         
                         [self.delegate authInputsView:self presentAlertController:self->inputsAlert];
                     }
                 }];
                
                // Async response
                return;
            }
            else
            {
                NSLog(@"[ForgotPasswordInputsView] Operation failed during the email identity stage");
            }
        }
        
        callback(nil, [NSError errorWithDomain:MXKAuthErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:[NSBundle mxk_localizedStringForKey:@"not_supported_yet"]}]);
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
    self.didPrepareParametersCallback = nil;
    self.parameters = nil;
    
    [self hideInputsContainer];
    
    self.messageLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"auth_reset_password_success_message", @"Vector", nil), self.emailTextField.text];
    
    self.messageLabel.hidden = NO;
}

#pragma mark - Internals

- (void)reset
{
    // Cancel email validation request
    [self.mxCurrentOperation cancel];
    self.mxCurrentOperation = nil;
    
    self.parameters = nil;
    self.didPrepareParametersCallback = nil;
    
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
        if (self.didPrepareParametersCallback)
        {
            self.didPrepareParametersCallback(self.parameters, nil);
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
