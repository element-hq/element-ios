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

#import "AuthenticationViewController.h"

#import "AppDelegate.h"

#import "AuthInputsView.h"
#import "ForgotPasswordInputsView.h"

#import "RageShakeManager.h"

#import "VectorDesignValues.h"

@interface AuthenticationViewController ()
{
    /**
     Store the potential login error received by using a default homeserver different from matrix.org
     while we retry a login process against the matrix.org HS.
     */
    NSError *loginError;
}

@end

@implementation AuthenticationViewController

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self)
                          bundle:[NSBundle bundleForClass:self]];
}

+ (instancetype)authenticationViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass(self)
                                          bundle:[NSBundle bundleForClass:self]];
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kVectorNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mainNavigationItem.title = nil;
    self.rightBarButtonItem.title = NSLocalizedStringFromTable(@"auth_register", @"Vector", nil);
    
    self.defaultHomeServerUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"homeserverurl"];
    self.homeServerTextField.textColor = kVectorTextColorBlack;
    self.homeServerLabel.textColor = kVectorTextColorGray;
    
    self.defaultIdentityServerUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"identityserverurl"];
    self.identityServerTextField.textColor = kVectorTextColorBlack;
    self.identityServerLabel.textColor = kVectorTextColorGray;
    
    self.welcomeImageView.image = [UIImage imageNamed:@"logo"];
    
    [self.submitButton.layer setCornerRadius:5];
    self.submitButton.clipsToBounds = YES;
    self.submitButton.backgroundColor = kVectorColorGreen;
    [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_login", @"Vector", nil) forState:UIControlStateNormal];
    [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_login", @"Vector", nil) forState:UIControlStateHighlighted];
    self.submitButton.enabled = YES;
    
    NSMutableAttributedString *forgotPasswordTitle = [[NSMutableAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"auth_forgot_password", @"Vector", nil)];
    [forgotPasswordTitle addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(0, forgotPasswordTitle.length)];
    [forgotPasswordTitle addAttribute:NSForegroundColorAttributeName value:kVectorColorGreen range:NSMakeRange(0, forgotPasswordTitle.length)];
    [self.forgotPasswordButton setAttributedTitle:forgotPasswordTitle forState:UIControlStateNormal];
    [self.forgotPasswordButton setAttributedTitle:forgotPasswordTitle forState:UIControlStateHighlighted];
    
    [self updateForgotPwdButtonVisibility];
    
    [self.serverOptionsTickButton setImage:[UIImage imageNamed:@"selection_untick"] forState:UIControlStateNormal];
    [self.serverOptionsTickButton setImage:[UIImage imageNamed:@"selection_untick"] forState:UIControlStateHighlighted];
    
    NSAttributedString *serverOptionsTitle = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"auth_use_server_options", @"Vector", nil) attributes:@{NSForegroundColorAttributeName : kVectorTextColorGray, NSFontAttributeName: [UIFont systemFontOfSize:14]}];
    [self.serverOptionsTickButton setAttributedTitle:serverOptionsTitle forState:UIControlStateNormal];
    [self.serverOptionsTickButton setAttributedTitle:serverOptionsTitle forState:UIControlStateHighlighted];
    
    [self hideServerOptionsContainer:YES];
    
    // The view controller dismiss itself on successful login.
    self.delegate = self;
    
    // Custom used authInputsView
    [self registerAuthInputsViewClass:AuthInputsView.class forAuthType:MXKAuthenticationTypeLogin];
    [self registerAuthInputsViewClass:AuthInputsView.class forAuthType:MXKAuthenticationTypeRegister];
    [self registerAuthInputsViewClass:ForgotPasswordInputsView.class forAuthType:MXKAuthenticationTypeForgotPassword];
    
    // Initialize the auth inputs display
    AuthInputsView *authInputsView = [AuthInputsView authInputsView];
    MXAuthenticationSession *authSession = [MXAuthenticationSession modelFromJSON:@{@"flows":@[@{@"stages":@[kMXLoginFlowTypePassword]}]}];
    [authInputsView setAuthSession:authSession withAuthType:MXKAuthenticationTypeLogin];
    self.authInputsView = authInputsView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Screen tracking (via Google Analytics)
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker)
    {
        [tracker set:kGAIScreenName value:@"Authentication"];
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    }
}

- (void)setAuthType:(MXKAuthenticationType)authType
{
    super.authType = authType;
    
    // Check a potential stored error.
    if (loginError)
    {
        // Restore the default HS
        NSLog(@"[AuthenticationVC] Switch back to default homeserver");
        [self setHomeServerTextFieldText:nil];
        loginError = nil;
    }
    
    if (authType == MXKAuthenticationTypeLogin)
    {
        [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_login", @"Vector", nil) forState:UIControlStateNormal];
        [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_login", @"Vector", nil) forState:UIControlStateHighlighted];
    }
    else if (authType == MXKAuthenticationTypeRegister)
    {
        [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_register", @"Vector", nil) forState:UIControlStateNormal];
        [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_register", @"Vector", nil) forState:UIControlStateHighlighted];
    }
    else if (authType == MXKAuthenticationTypeForgotPassword)
    {
        if (isPasswordReseted)
        {
            [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_return_to_login", @"Vector", nil) forState:UIControlStateNormal];
            [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_return_to_login", @"Vector", nil) forState:UIControlStateHighlighted];
        }
        else
        {
            [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_send_reset_email", @"Vector", nil) forState:UIControlStateNormal];
            [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_send_reset_email", @"Vector", nil) forState:UIControlStateHighlighted];
        }
    }
    
    [self updateForgotPwdButtonVisibility];
}

- (void)setAuthInputsView:(MXKAuthInputsView *)authInputsView
{
    [super setAuthInputsView:authInputsView];
    
    // Restore here the actual content view height.
    // Indeed this height has been modified according to the authInputsView height in the default implementation of MXKAuthenticationViewController.
    [self refreshContentViewHeightConstraint];
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled
{
    super.userInteractionEnabled = userInteractionEnabled;
    
    // Show/Hide server options
    if (_optionsContainer.hidden == userInteractionEnabled)
    {
        _optionsContainer.hidden = !userInteractionEnabled;
        
        [self refreshContentViewHeightConstraint];
    }
    
    // Update the label of the right bar button according to its actual action.
    if (!userInteractionEnabled)
    {
        // The right bar button is used to cancel the running request.
        self.rightBarButtonItem.title = NSLocalizedStringFromTable(@"cancel", @"Vector", nil);
    }
    else
    {
        // The right bar button is used to switch the authentication type.
        if (self.authType == MXKAuthenticationTypeLogin)
        {
            self.rightBarButtonItem.title = NSLocalizedStringFromTable(@"auth_register", @"Vector", nil);
        }
        else if (self.authType == MXKAuthenticationTypeRegister)
        {
            self.rightBarButtonItem.title = NSLocalizedStringFromTable(@"auth_login", @"Vector", nil);
        }
        else if (self.authType == MXKAuthenticationTypeForgotPassword)
        {
            // The right bar button is used to return to login.
            self.rightBarButtonItem.title = NSLocalizedStringFromTable(@"cancel", @"Vector", nil);
        }
    }
}

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == self.serverOptionsTickButton)
    {
        [self hideServerOptionsContainer:!self.serverOptionsContainer.hidden];
    }
    else if (sender == self.forgotPasswordButton)
    {
        // Update UI to reset password
        self.authType = MXKAuthenticationTypeForgotPassword;
    }
    else if (sender == self.rightBarButtonItem)
    {
        // Check whether a request is in progress
        if (!self.userInteractionEnabled)
        {
            // Cancel the current operation
            [self cancel];
        }
        else if (self.authType == MXKAuthenticationTypeLogin)
        {
            self.authType = MXKAuthenticationTypeRegister;
            self.rightBarButtonItem.title = NSLocalizedStringFromTable(@"auth_login", @"Vector", nil);
        }
        else
        {
            self.authType = MXKAuthenticationTypeLogin;
            self.rightBarButtonItem.title = NSLocalizedStringFromTable(@"auth_register", @"Vector", nil);
        }
    }
    else if (sender == self.submitButton)
    {
        // Check whether the user should set an email
        if (self.authInputsView.shouldPromptUserForEmailAddress)
        {
            [self dismissKeyboard];
            
            if (alert)
            {
                [alert dismiss:NO];
            }
            
             __weak typeof(self) weakSelf = self;
            
            alert = [[MXKAlert alloc] initWithTitle:NSLocalizedStringFromTable(@"warning", @"Vector", nil) message:NSLocalizedStringFromTable(@"auth_missing_optional_email", @"Vector", nil) style:MXKAlertStyleAlert];
            alert.cancelButtonIndex = [alert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                strongSelf->alert = nil;
            }];
            [alert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"continue"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                strongSelf->alert = nil;
                
                [super onButtonPressed:sender];
            }];
            [alert showInViewController:self];
        }
        else
        {
            [super onButtonPressed:sender];
        }
    }
    else
    {
        [super onButtonPressed:sender];
    }
}

- (void)onFailureDuringAuthRequest:(NSError *)error
{
    // Homeserver migration: When the default homeserver url is different from matrix.org,
    // the login (or forgot pwd) process with an existing matrix.org accounts will then fail.
    // Patch: Falling back to matrix.org HS so we don't break everyone's logins
    if ([self.homeServerTextField.text isEqualToString:self.defaultHomeServerUrl] && ![self.defaultHomeServerUrl isEqualToString:@"https://matrix.org"])
    {
        MXError *mxError = [[MXError alloc] initWithNSError:error];
        
        if (self.authType == MXKAuthenticationTypeLogin)
        {
            if (mxError && [mxError.errcode isEqualToString:kMXErrCodeStringForbidden])
            {
                // Falling back to matrix.org HS
                NSLog(@"[AuthenticationVC] Retry login against matrix.org");
                
                // Store the current error, and change the homeserver url
                loginError = error;
                [self setHomeServerTextFieldText:@"https://matrix.org"];
                
                // Trigger a new request
                [self onButtonPressed:self.submitButton];
                return;
            }
        }
        else if (self.authType == MXKAuthenticationTypeForgotPassword)
        {
            if (mxError && [mxError.errcode isEqualToString:kMXErrCodeStringNotFound])
            {
                // Sanity check
                if ([self.authInputsView isKindOfClass:ForgotPasswordInputsView.class])
                {
                    // Falling back to matrix.org HS
                    NSLog(@"[AuthenticationVC] Retry forgot password against matrix.org");
                    
                    // Store the current error, and change the homeserver url
                    loginError = error;
                    [self setHomeServerTextFieldText:@"https://matrix.org"];
                    
                    // Trigger a new request
                    ForgotPasswordInputsView *authInputsView = (ForgotPasswordInputsView*)self.authInputsView;
                    [authInputsView.nextStepButton sendActionsForControlEvents:UIControlEventTouchUpInside];
                    return;
                }
            }
        }
    }
    
    // Check whether we were retrying against matrix.org HS
    if (loginError)
    {
        // This is not an existing matrix.org accounts
        NSLog(@"[AuthenticationVC] This is not an existing matrix.org accounts");
        
        // Restore the default HS
        [self setHomeServerTextFieldText:nil];
        
        // Consider the original login error
        [super onFailureDuringAuthRequest:loginError];
        loginError = nil;
    }
    else
    {
        [super onFailureDuringAuthRequest:error];
    }
}

- (void)updateForgotPwdButtonVisibility
{
    self.forgotPasswordButton.hidden = (self.authType != MXKAuthenticationTypeLogin);
    
    // Adjust minimum leading constraint of the submit button
    if (self.forgotPasswordButton.isHidden)
    {
        self.submitButtonMinLeadingConstraint.constant = 19;
    }
    else
    {
        CGRect frame = self.forgotPasswordButton.frame;
        self.submitButtonMinLeadingConstraint.constant =  frame.origin.x + frame.size.width + 10;
    }
}

#pragma mark -

- (void)refreshContentViewHeightConstraint
{
    // Refresh content view height by considering the options container display.
    CGRect serverOptionsContainerFrame = self.serverOptionsContainer.frame;
    
    self.contentViewHeightConstraint.constant = self.optionsContainer.frame.origin.y + 10;
    
    if (!self.optionsContainer.isHidden)
    {
        self.contentViewHeightConstraint.constant += serverOptionsContainerFrame.origin.y;
        if (!self.serverOptionsContainer.isHidden)
        {
            self.contentViewHeightConstraint.constant += serverOptionsContainerFrame.size.height;
        }
    }
}

- (void)hideServerOptionsContainer:(BOOL)hidden
{
    if (self.serverOptionsContainer.isHidden == hidden)
    {
        return;
    }
    
    if (hidden)
    {
        [self.homeServerTextField resignFirstResponder];
        [self.identityServerTextField resignFirstResponder];
        
        // Report server url typed by the user as custom url.
        NSString *homeServerURL = self.homeServerTextField.text;
        if (homeServerURL.length && ![homeServerURL isEqualToString:self.defaultHomeServerUrl])
        {
            [[NSUserDefaults standardUserDefaults] setObject:homeServerURL forKey:@"customHomeServerURL"];
        }
        else
        {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"customHomeServerURL"];
        }
        
        NSString *identityServerURL = self.identityServerTextField.text;
        if (identityServerURL.length && ![identityServerURL isEqualToString:self.defaultIdentityServerUrl])
        {
            [[NSUserDefaults standardUserDefaults] setObject:identityServerURL forKey:@"customIdentityServerURL"];
        }
        else
        {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"customIdentityServerURL"];
        }
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // Restore default configuration
        [self setHomeServerTextFieldText:self.defaultHomeServerUrl];
        [self setIdentityServerTextFieldText:self.defaultIdentityServerUrl];
        
        [self.serverOptionsTickButton setImage:[UIImage imageNamed:@"selection_untick"] forState:UIControlStateNormal];
        self.serverOptionsContainer.hidden = YES;
        
        // Refresh content view height
        self.contentViewHeightConstraint.constant -= self.serverOptionsContainer.frame.size.height;
    }
    else
    {
        // Load custom configuration
        NSString *customHomeServerURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"customHomeServerURL"];
        if (customHomeServerURL.length)
        {
            [self setHomeServerTextFieldText:customHomeServerURL];
        }
        NSString *customIdentityServerURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"customIdentityServerURL"];
        if (customIdentityServerURL.length)
        {
            [self setIdentityServerTextFieldText:customIdentityServerURL];
        }
        
        [self.serverOptionsTickButton setImage:[UIImage imageNamed:@"selection_tick"] forState:UIControlStateNormal];
        self.serverOptionsContainer.hidden = NO;
        
        // Refresh content view height
        self.contentViewHeightConstraint.constant += self.serverOptionsContainer.frame.size.height;

        // Scroll to display server options
        CGPoint offset = self.authenticationScrollView.contentOffset;
        offset.y += self.serverOptionsContainer.frame.size.height;
        self.authenticationScrollView.contentOffset = offset;
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // Override here the handling of the authInputsView height change.
    if ([@"viewHeightConstraint.constant" isEqualToString:keyPath])
    {
        self.authInputContainerViewHeightConstraint.constant = self.authInputsView.viewHeightConstraint.constant;
        
        // Force to render the view
        [self.view layoutIfNeeded];
        
        // Refresh content view height by considering the updated frame of the options container.
        [self refreshContentViewHeightConstraint];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - MXKAuthenticationViewControllerDelegate

- (void)authenticationViewController:(MXKAuthenticationViewController *)authenticationViewController didLogWithUserId:(NSString *)userId
{
    // Hide server options in order to save customized inputs
    [self hideServerOptionsContainer:YES];
    
    // Remove auth view controller on successful login
    if (self.navigationController)
    {
        // Pop the view controller
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        // Dismiss on successful login
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
