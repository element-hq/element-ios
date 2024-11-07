/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "ForgotPasswordInputsView.h"

#import "MXHTTPOperation.h"
#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

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
    
    [self.nextStepButton setTitle:[VectorL10n authResetPasswordNextStepButton] forState:UIControlStateNormal];
    [self.nextStepButton setTitle:[VectorL10n authResetPasswordNextStepButton] forState:UIControlStateHighlighted];
    self.nextStepButton.enabled = YES;
    
    self.emailTextField.placeholder = [VectorL10n authEmailPlaceholder];
    self.passWordTextField.placeholder = [VectorL10n authNewPasswordPlaceholder];
    self.repeatPasswordTextField.placeholder = [VectorL10n authRepeatNewPasswordPlaceholder];
    
    // Apply placeholder color
    [self customizeViewRendering];
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
    
    self.messageLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    
    self.emailTextField.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.passWordTextField.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.repeatPasswordTextField.textColor = ThemeService.shared.theme.textPrimaryColor;
    
    self.emailSeparator.backgroundColor = ThemeService.shared.theme.lineBreakColor;
    self.passwordSeparator.backgroundColor = ThemeService.shared.theme.lineBreakColor;
    self.repeatPasswordSeparator.backgroundColor = ThemeService.shared.theme.lineBreakColor;
    
    self.messageLabel.numberOfLines = 0;
    
    [self.nextStepButton.layer setCornerRadius:5];
    self.nextStepButton.clipsToBounds = YES;
    self.nextStepButton.backgroundColor = ThemeService.shared.theme.tintColor;

    if (self.emailTextField.placeholder)
    {
        self.emailTextField.attributedPlaceholder = [[NSAttributedString alloc]
                                                     initWithString:self.emailTextField.placeholder
                                                     attributes:@{NSForegroundColorAttributeName: ThemeService.shared.theme.placeholderTextColor}];
    }
    if (self.passWordTextField.placeholder)
    {
        self.passWordTextField.attributedPlaceholder = [[NSAttributedString alloc]
                                                        initWithString:self.passWordTextField.placeholder
                                                        attributes:@{NSForegroundColorAttributeName: ThemeService.shared.theme.placeholderTextColor}];
    }
    if (self.repeatPasswordTextField.placeholder)
    {
        self.repeatPasswordTextField.attributedPlaceholder = [[NSAttributedString alloc]
                                                              initWithString:self.repeatPasswordTextField.placeholder
                                                              attributes:@{NSForegroundColorAttributeName: ThemeService.shared.theme.placeholderTextColor}];
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
        MXLogDebug(@"[ForgotPasswordInputsView] Missing email");
        errorMsg = [VectorL10n authResetPasswordMissingEmail];
    }
    else if (!self.passWordTextField.text.length)
    {
        MXLogDebug(@"[ForgotPasswordInputsView] Missing Passwords");
        errorMsg = [VectorL10n authResetPasswordMissingPassword];
    }
    else if (self.passWordTextField.text.length < 6)
    {
        MXLogDebug(@"[ForgotPasswordInputsView] Invalid Passwords");
        errorMsg = [VectorL10n authInvalidPassword];
    }
    else if ([self.repeatPasswordTextField.text isEqualToString:self.passWordTextField.text] == NO)
    {
        MXLogDebug(@"[ForgotPasswordInputsView] Passwords don't match");
        errorMsg = [VectorL10n authPasswordDontMatch];
    }
    else
    {
        // Check validity of the non empty email
        if ([MXTools isEmailAddress:self.emailTextField.text] == NO)
        {
            MXLogDebug(@"[ForgotPasswordInputsView] Invalid email");
            errorMsg = [VectorL10n authInvalidEmail];
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
            
            inputsAlert = [UIAlertController alertControllerWithTitle:[VectorL10n error] message:errorMsg preferredStyle:UIAlertControllerStyleAlert];
            
            [inputsAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                              self->inputsAlert = nil;
                                                              
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
                [self checkIdentityServerRequirement:restClient success:^{

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

                             NSMutableDictionary *threepidCreds = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                                  @"client_secret": clientSecret,
                                                                                                                  @"sid": sid
                                                                                                                  }];
                             if (restClient.identityServer)
                             {
                                 NSURL *identServerURL = [NSURL URLWithString:restClient.identityServer];
                                 threepidCreds[@"id_server"] = identServerURL.host;
                             }

                             strongSelf.parameters = @{
                                                       @"auth": @{
                                                               @"threepid_creds": threepidCreds,
                                                               @"type": kMXLoginFlowTypeEmailIdentity
                                                               },
                                                       @"new_password": strongSelf.passWordTextField.text
                                                       };

                             [strongSelf hideInputsContainer];

                             strongSelf.messageLabel.text = [VectorL10n authResetPasswordEmailValidationMessage:strongSelf.emailTextField.text];

                             strongSelf.messageLabel.hidden = NO;

                             [strongSelf.nextStepButton addTarget:strongSelf
                                                           action:@selector(didCheckEmail:)
                                                 forControlEvents:UIControlEventTouchUpInside];

                             strongSelf.nextStepButton.hidden = NO;
                         }
                     }
                                               failure:^(NSError *error)
                     {
                        MXLogDebug(@"[ForgotPasswordInputsView] Failed to request email token");

                         // Ignore connection cancellation error
                         if (([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled))
                         {
                             return;
                         }

                         NSString *errorMessage;

                         // Translate the potential MX error.
                         MXError *mxError = [[MXError alloc] initWithNSError:error];
                         if (mxError && [mxError.errcode isEqualToString:kMXErrCodeStringThreePIDNotFound])
                             errorMessage = [VectorL10n authEmailNotFound];
                         else if (mxError && [mxError.errcode isEqualToString:kMXErrCodeStringServerNotTrusted])
                             errorMessage = [VectorL10n authUntrustedIdServer];
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

                             self->inputsAlert = [UIAlertController alertControllerWithTitle:[VectorL10n error] message:errorMessage preferredStyle:UIAlertControllerStyleAlert];

                             [self->inputsAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
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
                } failure:^(NSError *error) {
                    callback(nil, error);
                }];

                // Async response
                return;
            }
            else
            {
                MXLogDebug(@"[ForgotPasswordInputsView] Operation failed during the email identity stage");
            }
        }
        
        callback(nil, [NSError errorWithDomain:MXKAuthErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:[VectorL10n notSupportedYet]}]);
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
    
    self.messageLabel.text = [VectorL10n authResetPasswordSuccessMessage];
    
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
    
    self.messageLabel.text = [VectorL10n authResetPasswordMessage];
    self.messageLabel.hidden = NO;
    
    self.emailContainer.hidden = NO;
    self.passwordContainer.hidden = NO;
    self.repeatPasswordContainer.hidden = NO;
    
    [self layoutIfNeeded];
}

- (void)checkIdentityServerRequirement:(MXRestClient*)mxRestClient success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    [mxRestClient supportedMatrixVersions:^(MXMatrixVersions *matrixVersions) {

        MXLogDebug(@"[ForgotPasswordInputsView] checkIdentityServerRequirement: %@", matrixVersions.doesServerRequireIdentityServerParam ? @"YES": @"NO");

        if (matrixVersions.doesServerRequireIdentityServerParam
            && !mxRestClient.identityServer)
        {
            failure([NSError errorWithDomain:MXKAuthErrorDomain
                                        code:0
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:[VectorL10n authResetPasswordErrorIsRequired]
                                               }]);
        }
        else
        {
            success();
        }

    } failure:failure];
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
