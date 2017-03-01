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

#import "AuthInputsView.h"

#import "VectorDesignValues.h"
#import "Tools.h"

#import "CountryPickerViewController.h"
#import "NBPhoneNumberUtil.h"

@interface AuthInputsView ()
{
    /**
     The current email validation
     */
    MXK3PID  *submittedEmail;
    
    /**
     The current msisdn validation
     */
    MXK3PID  *submittedMSISDN;
    CountryPickerViewController *phoneNumberCountryPicker;
    NBPhoneNumber *newPhoneNumber;
    
    /**
     The set of parameters ready to use for a registration.
     */
    NSDictionary *externalRegistrationParameters;
}

@end

@implementation AuthInputsView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self)
                          bundle:[NSBundle bundleForClass:self]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _repeatPasswordTextField.placeholder = NSLocalizedStringFromTable(@"auth_repeat_password_placeholder", @"Vector", nil);
    _repeatPasswordTextField.textColor = kVectorTextColorBlack;
    
    self.userLoginTextField.placeholder = NSLocalizedStringFromTable(@"auth_user_id_placeholder", @"Vector", nil);
    self.userLoginTextField.textColor = kVectorTextColorBlack;
    
    self.passWordTextField.placeholder = NSLocalizedStringFromTable(@"auth_password_placeholder", @"Vector", nil);
    self.passWordTextField.textColor = kVectorTextColorBlack;
    
    self.emailTextField.textColor = kVectorTextColorBlack;
    self.phoneTextField.textColor = kVectorTextColorBlack;
    
    self.messageLabel.numberOfLines = 0;
    
    _thirdPartyIdentifiersHidden = YES;
}

- (void)destroy
{
    [super destroy];
    
    submittedEmail = nil;
    submittedMSISDN = nil;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect lastItemFrame;
    
    if (self.recaptchaWebView.isHidden)
    {
        lastItemFrame = self.repeatPasswordContainer.frame;
    }
    else
    {
        lastItemFrame = self.recaptchaWebView.frame;
    }
    
    self.viewHeightConstraint.constant = lastItemFrame.origin.y + lastItemFrame.size.height;
}

#pragma mark -

- (BOOL)setAuthSession:(MXAuthenticationSession *)authSession withAuthType:(MXKAuthenticationType)authType;
{
    if (type == MXKAuthenticationTypeLogin || type == MXKAuthenticationTypeRegister)
    {
        // Validate first the provided session
        MXAuthenticationSession *validSession = [self validateAuthenticationSession:authSession];
        
        // Cancel email validation if any
        if (submittedEmail)
        {
            [submittedEmail cancelCurrentRequest];
            submittedEmail = nil;
        }
        
        // Cancel msisdn validation if any
        if (submittedMSISDN)
        {
            [submittedMSISDN cancelCurrentRequest];
            submittedMSISDN = nil;
        }
        
        // Reset external registration parameters
        externalRegistrationParameters = nil;
        
        // Reset UI by hidding all items
        [self hideInputsContainer];
        
        if ([super setAuthSession:validSession withAuthType:authType])
        {
            if (authType == MXKAuthenticationTypeLogin)
            {
                self.passWordTextField.returnKeyType = UIReturnKeyDone;
                
                self.userLoginTextField.placeholder = NSLocalizedStringFromTable(@"auth_user_id_placeholder", @"Vector", nil);
                
                self.userLoginContainer.hidden = NO;
                self.passwordContainer.hidden = NO;
                
                CGRect frame = self.passwordContainer.frame;
                self.viewHeightConstraint.constant = frame.origin.y + frame.size.height;
            }
            else
            {
                // Update the registration inputs layout by hidding third-party ids fields.
                self.thirdPartyIdentifiersHidden = _thirdPartyIdentifiersHidden;
            }
            
            return YES;
        }
    }
    
    return NO;
}

- (NSString*)validateParameters
{
    // Consider everything is fine when external registration parameters are ready to use
    if (externalRegistrationParameters)
    {
        return nil;
    }
    
    // Check the validity of the parameters
    NSString *errorMsg = nil;
    
    // Remove whitespace in user login text field
    NSString *userLogin = self.userLoginTextField.text;
    self.userLoginTextField.text = [userLogin stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (type == MXKAuthenticationTypeLogin)
    {
        if (self.isPasswordBasedFlowSupported)
        {
            // Check required fields
            if (!self.userLoginTextField.text.length || !self.passWordTextField.text.length)
            {
                NSLog(@"[AuthInputsView] Invalid user/password");
                errorMsg = NSLocalizedStringFromTable(@"auth_invalid_login_param", @"Vector", nil);
            }
        }
        else
        {
            errorMsg = [NSBundle mxk_localizedStringForKey:@"not_supported_yet"];
        }
    }
    else if (type == MXKAuthenticationTypeRegister)
    {
        if (self.isThirdPartyIdentifiersHidden)
        {
            if (!self.userLoginTextField.text.length)
            {
                NSLog(@"[AuthInputsView] Invalid user name");
                errorMsg = NSLocalizedStringFromTable(@"auth_invalid_user_name", @"Vector", nil);
            }
            else if (!self.passWordTextField.text.length)
            {
                NSLog(@"[AuthInputsView] Missing Passwords");
                errorMsg = NSLocalizedStringFromTable(@"auth_missing_password", @"Vector", nil);
            }
            else if (self.passWordTextField.text.length < 6)
            {
                NSLog(@"[AuthInputsView] Invalid Passwords");
                errorMsg = NSLocalizedStringFromTable(@"auth_invalid_password", @"Vector", nil);
            }
            else if ([self.repeatPasswordTextField.text isEqualToString:self.passWordTextField.text] == NO)
            {
                NSLog(@"[AuthInputsView] Passwords don't match");
                errorMsg = NSLocalizedStringFromTable(@"auth_password_dont_match", @"Vector", nil);
            }
            else
            {
                // Check validity of the non empty user name
                NSString *user = self.userLoginTextField.text;
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[a-z0-9.\\-_]+$" options:NSRegularExpressionCaseInsensitive error:nil];
                
                if ([regex firstMatchInString:user options:0 range:NSMakeRange(0, user.length)] == nil)
                {
                    NSLog(@"[AuthInputsView] Invalid user name");
                    errorMsg = NSLocalizedStringFromTable(@"auth_invalid_user_name", @"Vector", nil);
                }
            }
        }
        else
        {
            if (self.isEmailIdentityFlowRequired && !self.emailTextField.text.length)
            {
                NSLog(@"[AuthInputsView] Missing email");
                errorMsg = NSLocalizedStringFromTable(@"auth_missing_email", @"Vector", nil);
            }
            else if (self.isMSISDNFlowRequired && !self.phoneTextField.text.length)
            {
                NSLog(@"[AuthInputsView] Missing phone");
                errorMsg = NSLocalizedStringFromTable(@"auth_missing_phone", @"Vector", nil);
            }
            else
            {
                if (self.emailTextField.text.length)
                {
                    // Check validity of the non empty email
                    if (![MXTools isEmailAddress:self.emailTextField.text])
                    {
                        NSLog(@"[AuthInputsView] Invalid email");
                        errorMsg = NSLocalizedStringFromTable(@"auth_invalid_email", @"Vector", nil);
                    }
                }
                
                if (!errorMsg && newPhoneNumber)
                {
                    // Check validity of the non empty phone
                    if (![[NBPhoneNumberUtil sharedInstance] isValidNumber:newPhoneNumber])
                    {
                        NSLog(@"[AuthInputsView] Invalid phone number");
                        errorMsg = NSLocalizedStringFromTable(@"auth_invalid_phone", @"Vector", nil);
                    }
                }
            }
        }
    }
    
    return errorMsg;
}

- (void)prepareParameters:(void (^)(NSDictionary *parameters))callback
{
    if (callback)
    {
        // Return external registration parameters if any
        if (externalRegistrationParameters)
        {
            // We trigger here a registration based on external inputs. All the required data are handled by the session id.
            NSLog(@"[AuthInputsView] prepareParameters: return external registration parameters");
            callback(externalRegistrationParameters);
            
            // CAUTION: Do not reset this dictionary here, it is used later to handle this registration until the end (see [updateAuthSessionWithCompletedStages:didUpdateParameters:])
        }
        
        // Prepare here parameters dict by checking each required fields.
        NSDictionary *parameters = nil;
        
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
            // Handle here the supported login flow
            if (type == MXKAuthenticationTypeLogin)
            {
                if (self.isPasswordBasedFlowSupported)
                {
                    //Check whether user login is an email or a username.
                    NSString *user = self.userLoginTextField.text;
                    
                    if ([MXTools isEmailAddress:user])
                    {
                        parameters = @{
                                       @"type": kMXLoginFlowTypePassword,
                                       @"medium": kMX3PIDMediumEmail,
                                       @"address": user,
                                       @"password": self.passWordTextField.text
                                       };
                    }
                    else
                    {
                        // Retrieve the MCC (from the SIM card information)
                        // Note: the phone book country code is not defined yet
                        NSString *MCC = [MXKAppSettings standardAppSettings].phonebookCountryCode;
                        
                        // Check whether the user login is a valid phone number.
                        NSString *msisdn = [MXKTools msisdnWithPhoneNumber:user andCountryCode:MCC];
                        
                        if (msisdn)
                        {
                            parameters = @{
                                           @"type": kMXLoginFlowTypePassword,
                                           @"medium": kMX3PIDMediumMSISDN,
                                           @"address": msisdn,
                                           @"password": self.passWordTextField.text
                                           };
                        }
                        else
                        {
                            parameters = @{
                                           @"type": kMXLoginFlowTypePassword,
                                           @"user": user,
                                           @"password": self.passWordTextField.text
                                           };
                        }
                    }
                }
            }
            else if (type == MXKAuthenticationTypeRegister)
            {
                // Check whether an email has been set, and if it is not handled yet
                if (!self.emailContainer.isHidden && self.emailTextField.text.length && !self.isEmailIdentityFlowCompleted)
                {
                    // Retrieve the REST client from delegate
                    MXRestClient *restClient;
                    
                    if (self.delegate && [self.delegate respondsToSelector:@selector(authInputsViewEmailValidationRestClient:)])
                    {
                        restClient = [self.delegate authInputsViewEmailValidationRestClient:self];
                    }
                    
                    if (restClient)
                    {
                        // Launch email validation
                        submittedEmail = [[MXK3PID alloc] initWithMedium:kMX3PIDMediumEmail andAddress:self.emailTextField.text];

                        // Create the next link that is common to all Vector.im clients
                        NSString *nextLink = [NSString stringWithFormat:@"%@/#/register?client_secret=%@&hs_url=%@&is_url=%@&session_id=%@",
                                              [Tools webAppUrl],
                                              [submittedEmail.clientSecret stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]],
                                              [restClient.homeserver stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]],
                                              [restClient.identityServer stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]],
                                              [currentSession.session stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];

                        [submittedEmail requestValidationTokenWithMatrixRestClient:restClient
                                                                          nextLink:nextLink
                                                                           success:^{
                                                                               
                                                                               NSURL *identServerURL = [NSURL URLWithString:restClient.identityServer];
                                                                               NSDictionary *parameters;
                                                                               parameters = @{
                                                                                              @"auth": @{@"session":currentSession.session, @"threepid_creds": @{@"client_secret": submittedEmail.clientSecret, @"id_server": identServerURL.host, @"sid": submittedEmail.sid}, @"type": kMXLoginFlowTypeEmailIdentity},
                                                                                              @"username": self.userLoginTextField.text,
                                                                                              @"password": self.passWordTextField.text,
                                                                                              @"bind_email": @(YES)
                                                                                              };
                                                                               
                                                                               [self hideInputsContainer];
                                                                               
                                                                               self.messageLabel.text = NSLocalizedStringFromTable(@"auth_email_validation_message", @"Vector", nil);
                                                                               self.messageLabel.hidden = NO;
                                                                               
                                                                               callback(parameters);
                                                                               
                                                                           } failure:^(NSError *error) {
                                                                               
                                                                               NSLog(@"[AuthInputsView] Failed to request email token");
                                                                               
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
                    else if (self.isEmailIdentityFlowRequired)
                    {
                        NSLog(@"[AuthInputsView] Authentication failed during the email identity stage");
                    }
                }
                else if (self.isRecaptchaFlowRequired)
                {
                    [self displayRecaptchaForm:^(NSString *response) {
                        
                        if (response.length)
                        {
                            NSDictionary *parameters = @{
                                                         @"auth": @{@"session":currentSession.session, @"response": response, @"type": kMXLoginFlowTypeRecaptcha},
                                                         @"username": self.userLoginTextField.text,
                                                         @"password": self.passWordTextField.text,
                                                         @"bind_email": [NSNumber numberWithBool:self.isEmailIdentityFlowCompleted]
                                                         };
                            
                            callback(parameters);
                        }
                        else
                        {
                            NSLog(@"[AuthInputsView] reCaptcha stage failed");
                            callback(nil);
                        }
                        
                    }];
                    
                    // Async response
                    return;
                }
                else if (self.isDummyFlowSupported)
                {
                    parameters = @{
                                   @"auth": @{@"session":currentSession.session, @"type": kMXLoginFlowTypeDummy},
                                   @"username": self.userLoginTextField.text,
                                   @"password": self.passWordTextField.text,
                                   @"bind_email": @(NO)
                                   };
                }
                else if (self.isPasswordBasedFlowSupported)
                {
                    // Note: this use case was not tested yet.
                    parameters = @{
                                   @"auth": @{@"session":currentSession.session, @"username": self.userLoginTextField.text, @"password": self.passWordTextField.text, @"type": kMXLoginFlowTypePassword}
                                   };
                }
            }
        }
        
        callback(parameters);
    }
}

- (void)updateAuthSessionWithCompletedStages:(NSArray *)completedStages didUpdateParameters:(void (^)(NSDictionary *parameters))callback
{
    if (callback)
    {
        if (currentSession)
        {
            currentSession.completed = completedStages;
            
            // Check the supported use case
            if ([completedStages indexOfObject:kMXLoginFlowTypeEmailIdentity] != NSNotFound && self.isRecaptchaFlowRequired)
            {
                [self displayRecaptchaForm:^(NSString *response) {
                    
                    if (response.length)
                    {
                        // Update the parameters dict
                        NSDictionary *parameters;
                        
                        if (externalRegistrationParameters)
                        {
                            // We finalize here a registration triggered from external inputs. All the required data are handled by the session id
                            parameters = @{
                                           @"auth": @{@"session": currentSession.session, @"response": response, @"type": kMXLoginFlowTypeRecaptcha},
                                           };
                        }
                        else
                        {
                            parameters = @{
                                           @"auth": @{@"session": currentSession.session, @"response": response, @"type": kMXLoginFlowTypeRecaptcha},
                                           @"username": self.userLoginTextField.text,
                                           @"password": self.passWordTextField.text,
                                           @"bind_email": @(YES)
                                           };
                        }
                        
                        
                        callback (parameters);
                    }
                    else
                    {
                        NSLog(@"[AuthInputsView] reCaptcha stage failed");
                        callback (nil);
                    }
                    
                }];
                
                return;
            }
        }
        
        NSLog(@"[AuthInputsView] updateAuthSessionWithCompletedStages failed");
        callback (nil);
    }
}

- (BOOL)setExternalRegistrationParameters:(NSDictionary *)registrationParameters
{
    // Presently we only support a registration based on next_link associated to a successful email validation.
    NSString *homeserverURL;
    NSString *identityURL;
    
    // Check the current authentication type
    if (self.authType != MXKAuthenticationTypeRegister)
    {
        NSLog(@"[AuthInputsView] setExternalRegistrationParameters failed: wrong auth type");
        return NO;
    }
    
    // Retrieve the REST client from delegate
    MXRestClient *restClient;
    if (self.delegate && [self.delegate respondsToSelector:@selector(authInputsViewEmailValidationRestClient:)])
    {
        restClient = [self.delegate authInputsViewEmailValidationRestClient:self];
    }
    
    if (restClient)
    {
        // Sanity check on home server
        id hs_url = registrationParameters[@"hs_url"];
        if (hs_url && [hs_url isKindOfClass:NSString.class])
        {
            homeserverURL = hs_url;
            
            if ([homeserverURL isEqualToString:restClient.homeserver] == NO)
            {
                NSLog(@"[AuthInputsView] setExternalRegistrationParameters failed: wrong homeserver URL");
                return NO;
            }
        }
        
        // Sanity check on identity server
        id is_url = registrationParameters[@"is_url"];
        if (is_url && [is_url isKindOfClass:NSString.class])
        {
            identityURL = is_url;
            
            if ([identityURL isEqualToString:restClient.identityServer] == NO)
            {
                NSLog(@"[AuthInputsView] setExternalRegistrationParameters failed: wrong identity server URL");
                return NO;
            }
        }
    }
    else
    {
        NSLog(@"[AuthInputsView] setExternalRegistrationParameters failed: not supported");
        return NO;
    }
    
    // Retrieve other parameters
    NSString *clientSecret;
    NSString *sid;
    NSString *sessionId;
    
    id value = registrationParameters[@"client_secret"];
    if (value && [value isKindOfClass:NSString.class])
    {
        clientSecret = value;
    }
    value = registrationParameters[@"sid"];
    if (value && [value isKindOfClass:NSString.class])
    {
        sid = value;
    }
    value = registrationParameters[@"session_id"];
    if (value && [value isKindOfClass:NSString.class])
    {
        sessionId = value;
    }
    
    // Check validity of the required parameters
    if (!homeserverURL.length || !identityURL.length || !clientSecret.length || !sid.length || !sessionId.length)
    {
        NSLog(@"[AuthInputsView] setExternalRegistrationParameters failed: wrong parameters");
        return NO;
    }
    
    // Prepare the registration parameters (Ready to use)
    NSURL *identServerURL = [NSURL URLWithString:identityURL];
    externalRegistrationParameters = @{
                                       @"auth": @{@"session": sessionId, @"threepid_creds": @{@"client_secret": clientSecret, @"id_server": identServerURL.host, @"sid": sid}, @"type": kMXLoginFlowTypeEmailIdentity},
                                       };
    
    // Hide all inputs by default
    [self hideInputsContainer];
    
    return YES;
}

- (BOOL)areAllRequiredFieldsSet
{
    // Keep enable the submit button.
    return YES;
}

- (void)dismissKeyboard
{
    [self.userLoginTextField resignFirstResponder];
    [self.passWordTextField resignFirstResponder];
    [self.emailTextField resignFirstResponder];
    [self.repeatPasswordTextField resignFirstResponder];
    
    [super dismissKeyboard];
}

- (NSString*)userId
{
    return self.userLoginTextField.text;
}

- (NSString*)password
{
    return self.passWordTextField.text;
}

#pragma mark -

- (BOOL)isThirdPartyIdentifiersSupported
{
    return (self.isEmailIdentityFlowSupported || self.isMSISDNFlowSupported);
}


- (void)setThirdPartyIdentifiersHidden:(BOOL)thirdPartyIdentifiersHidden
{
    [self hideInputsContainer];
    
    CGFloat viewHeight = 0;
    
    if (thirdPartyIdentifiersHidden)
    {
        self.passWordTextField.returnKeyType = UIReturnKeyNext;
        
        self.userLoginTextField.placeholder = NSLocalizedStringFromTable(@"auth_user_name_placeholder", @"Vector", nil);
        
        self.userLoginContainer.hidden = NO;
        self.passwordContainer.hidden = NO;
        self.repeatPasswordContainer.hidden = NO;
        
        viewHeight = 150;
    }
    else
    {
        if (self.isEmailIdentityFlowSupported)
        {
            if (self.isEmailIdentityFlowRequired)
            {
                self.emailTextField.placeholder = NSLocalizedStringFromTable(@"auth_email_placeholder", @"Vector", nil);
            }
            else
            {
                self.emailTextField.placeholder = NSLocalizedStringFromTable(@"auth_optional_email_placeholder", @"Vector", nil);
            }
            
            self.emailContainer.hidden = NO;
            
            self.messageLabel.hidden = NO;
            self.messageLabel.text = NSLocalizedStringFromTable(@"auth_add_email_message", @"Vector", nil);
            
            viewHeight = 50;
        }
        
        if (self.isMSISDNFlowSupported)
        {
            if (self.isMSISDNFlowRequired)
            {
                self.phoneTextField.placeholder = NSLocalizedStringFromTable(@"auth_phone_placeholder", @"Vector", nil);
            }
            else
            {
                self.phoneTextField.placeholder = NSLocalizedStringFromTable(@"auth_optional_phone_placeholder", @"Vector", nil);
            }
            
            self.phoneContainer.hidden = NO;
            
            if (!_emailContainer.isHidden)
            {
                self.emailTextField.returnKeyType = UIReturnKeyNext;
                
                self.phoneContainerTopConstraint.constant = 50;
                
                self.messageLabel.text = NSLocalizedStringFromTable(@"auth_add_email_msisdn_message", @"Vector", nil);
                
                viewHeight = 100;
            }
            else
            {
                self.messageLabel.hidden = NO;
                self.messageLabel.text = NSLocalizedStringFromTable(@"auth_add_phone_message", @"Vector", nil);
                
                viewHeight = 50;
            }
        }
        
        if (!self.messageLabel.isHidden)
        {
            [self.messageLabel sizeToFit];
            
            CGRect frame = self.messageLabel.frame;
            
            CGFloat offset = frame.origin.x + frame.size.height;
            
            self.emailContainerTopConstraint.constant = offset;
            self.phoneContainerTopConstraint.constant += offset;
            viewHeight += offset;
        }
    }
    
    self.viewHeightConstraint.constant = viewHeight;
    
    _thirdPartyIdentifiersHidden = thirdPartyIdentifiersHidden;
}

- (IBAction)selectPhoneNumberCountry:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(authInputsView:presentViewController:)])
    {
        phoneNumberCountryPicker = [CountryPickerViewController countryPickerViewController];
        phoneNumberCountryPicker.delegate = self;
        phoneNumberCountryPicker.showCountryCallingCode = YES;
        
        [self.delegate authInputsView:self presentViewController:phoneNumberCountryPicker];
    }
}

- (void)setIsoCountryCode:(NSString *)isoCountryCode
{
    _isoCountryCode = isoCountryCode;
    
    NSNumber *callingCode = [[NBPhoneNumberUtil sharedInstance] getCountryCodeForRegion:isoCountryCode];
    
    self.callingCodeLabel.text = [NSString stringWithFormat:@"+%@", callingCode.stringValue];
    
    self.isoCountryCodeLabel.text = isoCountryCode;
    
    // Update displayed phone
    [self textFieldDidChange:self.phoneTextField];
}

- (void)resetThirdPartyIdentifiers
{
    [self dismissKeyboard];
    
    self.emailTextField.text = nil;
    self.phoneTextField.text = nil;

    newPhoneNumber = nil;
}

#pragma mark - MXKCountryPickerViewControllerDelegate

- (void)countryPickerViewController:(MXKCountryPickerViewController *)countryPickerViewController didSelectCountry:(NSString *)isoCountryCode
{
    self.isoCountryCode = isoCountryCode;
            
    newPhoneNumber = [[NBPhoneNumberUtil sharedInstance] parse:self.phoneTextField.text defaultRegion:isoCountryCode error:nil];
    [self formatNewPhoneNumber];
    
    [countryPickerViewController withdrawViewControllerAnimated:YES completion:nil];
    phoneNumberCountryPicker = nil;
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
        if (textField == self.userLoginTextField)
        {
            [self.passWordTextField becomeFirstResponder];
        }
        else if (textField == self.passWordTextField)
        {
            [self.repeatPasswordTextField becomeFirstResponder];
        }
        else if (textField == self.emailTextField)
        {
            [self.phoneTextField becomeFirstResponder];
        }
    }
    
    return YES;
}

#pragma mark - TextField listener

- (IBAction)textFieldDidChange:(id)sender
{
    UITextField* textField = (UITextField*)sender;
    
    if (textField == self.phoneTextField)
    {
        newPhoneNumber = [[NBPhoneNumberUtil sharedInstance] parse:self.phoneTextField.text defaultRegion:self.isoCountryCode error:nil];
        
        [self formatNewPhoneNumber];
    }
}

#pragma mark -

- (void)hideInputsContainer
{
    // Hide all inputs container
    self.userLoginContainer.hidden = YES;
    self.passwordContainer.hidden = YES;
    self.emailContainer.hidden = YES;
    self.phoneContainer.hidden = YES;
    self.repeatPasswordContainer.hidden = YES;
    
    // Hide other items
    self.messageLabel.hidden = YES;
    self.recaptchaWebView.hidden = YES;
}

- (void)formatNewPhoneNumber
{
    if (newPhoneNumber)
    {
        NSString *formattedNumber = [[NBPhoneNumberUtil sharedInstance] format:newPhoneNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL error:nil];
        NSString *prefix = self.callingCodeLabel.text;
        if ([formattedNumber hasPrefix:prefix])
        {
            // Format the display phone number
            self.phoneTextField.text = [formattedNumber substringFromIndex:prefix.length];
        }
    }
}

- (BOOL)displayRecaptchaForm:(void (^)(NSString *response))callback
{
    // Retrieve the site key
    NSString *siteKey;
    
    id recaptchaParams = [currentSession.params objectForKey:kMXLoginFlowTypeRecaptcha];
    if (recaptchaParams && [recaptchaParams isKindOfClass:NSDictionary.class])
    {
        NSDictionary *recaptchaParamsDict = (NSDictionary*)recaptchaParams;
        siteKey = [recaptchaParamsDict objectForKey:@"public_key"];
    }
    
    // Retrieve the REST client from delegate
    MXRestClient *restClient;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(authInputsViewEmailValidationRestClient:)])
    {
        restClient = [self.delegate authInputsViewEmailValidationRestClient:self];
    }
    
    // Sanity check
    if (siteKey.length && restClient && callback)
    {
        [self hideInputsContainer];
        
        self.messageLabel.hidden = NO;
        self.messageLabel.text = NSLocalizedStringFromTable(@"auth_recaptcha_message", @"Vector", nil);
        
        self.recaptchaWebView.hidden = NO;
        CGRect frame = self.recaptchaWebView.frame;
        self.viewHeightConstraint.constant = frame.origin.y + frame.size.height;
        
        [self.recaptchaWebView openRecaptchaWidgetWithSiteKey:siteKey fromHomeServer:restClient.homeserver callback:callback];
        
        return YES;
    }
    
    return NO;
}

// Tell whether a flow type is supported or not by this view.
- (BOOL)isSupportedFlowType:(MXLoginFlowType)flowType
{
    if ([flowType isEqualToString:kMXLoginFlowTypePassword])
    {
        return YES;
    }
    else if ([flowType isEqualToString:kMXLoginFlowTypeEmailIdentity])
    {
        return YES;
    }
    else if ([flowType isEqualToString:kMXLoginFlowTypeRecaptcha])
    {
        return YES;
    }
    else if ([flowType isEqualToString:kMXLoginFlowTypeMSISDN])
    {
        return YES;
    }
    else if ([flowType isEqualToString:kMXLoginFlowTypeDummy])
    {
        return YES;
    }
    
    return NO;
}

- (MXAuthenticationSession*)validateAuthenticationSession:(MXAuthenticationSession*)authSession
{
    // Check whether the listed flows in this authentication session are supported
    NSMutableArray *supportedFlows = [NSMutableArray array];
    
    for (MXLoginFlow* flow in authSession.flows)
    {
        // Check whether flow type is defined
        if (flow.type)
        {
            if ([self isSupportedFlowType:flow.type])
            {
                // Check here all stages
                BOOL isSupported = YES;
                if (flow.stages.count)
                {
                    for (NSString *stage in flow.stages)
                    {
                        if ([self isSupportedFlowType:stage] == NO)
                        {
                            NSLog(@"[AuthInputsView] %@: %@ stage is not supported.", (type == MXKAuthenticationTypeLogin ? @"login" : @"register"), stage);
                            isSupported = NO;
                            break;
                        }
                    }
                }
                else
                {
                    flow.stages = @[flow.type];
                }
                
                if (isSupported)
                {
                    [supportedFlows addObject:flow];
                }
            }
            else
            {
                NSLog(@"[AuthInputsView] %@: %@ stage is not supported.", (type == MXKAuthenticationTypeLogin ? @"login" : @"register"), flow.type);
            }
        }
        else
        {
            // Check here all stages
            BOOL isSupported = YES;
            if (flow.stages.count)
            {
                for (NSString *stage in flow.stages)
                {
                    if ([self isSupportedFlowType:stage] == NO)
                    {
                        NSLog(@"[AuthInputsView] %@: %@ stage is not supported.", (type == MXKAuthenticationTypeLogin ? @"login" : @"register"), stage);
                        isSupported = NO;
                        break;
                    }
                }
            }
            
            if (isSupported)
            {
                [supportedFlows addObject:flow];
            }
        }
    }
    
    if (supportedFlows.count)
    {
        if (supportedFlows.count == authSession.flows.count)
        {
            // Return the original session.
            return authSession;
        }
        else
        {
            // Keep only the supported flow.
            MXAuthenticationSession *updatedAuthSession = [[MXAuthenticationSession alloc] init];
            updatedAuthSession.session = authSession.session;
            updatedAuthSession.params = authSession.params;
            updatedAuthSession.flows = supportedFlows;
            return updatedAuthSession;
        }
    }
    
    return nil;
}

- (BOOL)isPasswordBasedFlowSupported
{
    if (currentSession)
    {
        for (MXLoginFlow *loginFlow in currentSession.flows)
        {
            if ([loginFlow.type isEqualToString:kMXLoginFlowTypePassword] || [loginFlow.stages indexOfObject:kMXLoginFlowTypePassword] != NSNotFound)
            {
                return YES;
            }
        }
    }
    
    return NO;
}

- (BOOL)isEmailIdentityFlowSupported
{
    if (currentSession)
    {
        for (MXLoginFlow *loginFlow in currentSession.flows)
        {
            if ([loginFlow.stages indexOfObject:kMXLoginFlowTypeEmailIdentity] != NSNotFound || [loginFlow.type isEqualToString:kMXLoginFlowTypeEmailIdentity])
            {
                return YES;
            }
        }
    }
    
    return NO;
}

- (BOOL)isEmailIdentityFlowRequired
{
    if (currentSession && currentSession.flows)
    {
        for (MXLoginFlow *loginFlow in currentSession.flows)
        {
            if ([loginFlow.stages indexOfObject:kMXLoginFlowTypeEmailIdentity] == NSNotFound && ![loginFlow.type isEqualToString:kMXLoginFlowTypeEmailIdentity])
            {
                return NO;
            }
        }
        
        return YES;
    }
    
    return NO;
}

- (BOOL)isEmailIdentityFlowCompleted
{
    if (currentSession && currentSession.completed)
    {
        if ([currentSession.completed indexOfObject:kMXLoginFlowTypeEmailIdentity] != NSNotFound)
        {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)isMSISDNFlowSupported
{
    if (currentSession)
    {
        for (MXLoginFlow *loginFlow in currentSession.flows)
        {
            if ([loginFlow.stages indexOfObject:kMXLoginFlowTypeMSISDN] != NSNotFound || [loginFlow.type isEqualToString:kMXLoginFlowTypeMSISDN])
            {
                return YES;
            }
        }
    }
    
    return NO;
}

- (BOOL)isMSISDNFlowRequired
{
    if (currentSession && currentSession.flows)
    {
        for (MXLoginFlow *loginFlow in currentSession.flows)
        {
            if ([loginFlow.stages indexOfObject:kMXLoginFlowTypeMSISDN] == NSNotFound && ![loginFlow.type isEqualToString:kMXLoginFlowTypeMSISDN])
            {
                return NO;
            }
        }
        
        return YES;
    }
    
    return NO;
}

- (BOOL)isMSISDNFlowCompleted
{
    if (currentSession && currentSession.completed)
    {
        if ([currentSession.completed indexOfObject:kMXLoginFlowTypeMSISDN] != NSNotFound)
        {
            return YES;
        }
    }
    
    return NO;
}


- (BOOL)isRecaptchaFlowRequired
{
    if (currentSession && currentSession.flows)
    {
        for (MXLoginFlow *loginFlow in currentSession.flows)
        {
            if ([loginFlow.stages indexOfObject:kMXLoginFlowTypeRecaptcha] == NSNotFound && ![loginFlow.type isEqualToString:kMXLoginFlowTypeRecaptcha])
            {
                return NO;
            }
        }
        
        return YES;
    }
    
    return NO;
}

- (BOOL)isDummyFlowSupported
{
    if (currentSession)
    {
        for (MXLoginFlow *loginFlow in currentSession.flows)
        {
            if ([loginFlow.stages indexOfObject:kMXLoginFlowTypeDummy] != NSNotFound || [loginFlow.type isEqualToString:kMXLoginFlowTypeDummy])
            {
                return YES;
            }
        }
    }
    
    return NO;
}

@end
