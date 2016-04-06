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

#import "AuthInputsView.h"

#import "RageShakeManager.h"

#import "VectorDesignValues.h"

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kVectorNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    self.mainNavigationItem.title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
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
    
    [self.forgotPasswordButton setTitle:NSLocalizedStringFromTable(@"auth_forgot_password", @"Vector", nil) forState:UIControlStateNormal];
    [self.forgotPasswordButton setTitle:NSLocalizedStringFromTable(@"auth_forgot_password", @"Vector", nil) forState:UIControlStateHighlighted];
    [self.forgotPasswordButton setTitleColor:kVectorTextColorGray forState:UIControlStateNormal];
    [self.forgotPasswordButton setTitleColor:kVectorTextColorGray forState:UIControlStateHighlighted];
    
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
    
    // Initialize the auth inputs display
    AuthInputsView *authInputsView = [AuthInputsView authInputsView];
    MXAuthenticationSession *authSession = [MXAuthenticationSession modelFromJSON:@{@"flows":@[@{@"stages":@[kMXLoginFlowTypePassword]}]}];
    [authInputsView setAuthSession:authSession withAuthType:MXKAuthenticationTypeLogin];
    self.authInputsView = authInputsView;
    
    // FIXME handle "Forgot password"
    self.forgotPasswordButton.hidden = YES;
}

- (void)setAuthType:(MXKAuthenticationType)authType
{
    super.authType = authType;
    
    if (authType == MXKAuthenticationTypeLogin)
    {
        [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_login", @"Vector", nil) forState:UIControlStateNormal];
        [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_login", @"Vector", nil) forState:UIControlStateHighlighted];
    }
    else
    {
        [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_register", @"Vector", nil) forState:UIControlStateNormal];
        [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_register", @"Vector", nil) forState:UIControlStateHighlighted];
    }
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled
{
    super.userInteractionEnabled = userInteractionEnabled;
    
    // Show/Hide server options
    _optionsContainer.hidden = !userInteractionEnabled;
}

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == self.serverOptionsTickButton)
    {
        [self hideServerOptionsContainer:!self.serverOptionsContainer.hidden];
    }
    else if (sender == self.forgotPasswordButton)
    {
        // TODO
    }
    else if (sender == self.rightBarButtonItem)
    {
        if (self.authType == MXKAuthenticationTypeLogin)
        {
            self.authType = MXKAuthenticationTypeRegister;
            self.rightBarButtonItem.title = NSLocalizedStringFromTable(@"auth_login", @"Vector", nil);
            // FIXME handle "Forgot password"
//            self.forgotPasswordButton.hidden = YES;
        }
        else
        {
            self.authType = MXKAuthenticationTypeLogin;
            self.rightBarButtonItem.title = NSLocalizedStringFromTable(@"auth_register", @"Vector", nil);
            // FIXME handle "Forgot password"
//            self.forgotPasswordButton.hidden = NO;
        }
    }
    else if (sender == self.submitButton)
    {
        // Check whether the user should set the email
        if (self.authInputsView.shouldPromptUserForEmailAddress)
        {
            [self dismissKeyboard];
            
            if (alert)
            {
                [alert dismiss:NO];
            }
            
             __weak typeof(self) weakSelf = self;
            
            alert = [[MXKAlert alloc] initWithTitle:NSLocalizedStringFromTable(@"warning", @"Vector", nil) message:NSLocalizedStringFromTable(@"auth_missing_optional_email", @"Vector", nil) style:MXKAlertStyleAlert];
            [alert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"continue"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                strongSelf->alert = nil;
                
                [super onButtonPressed:sender];
            }];
            alert.cancelButtonIndex = [alert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                strongSelf->alert = nil;
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

#pragma mark -

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
