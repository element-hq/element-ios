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

#import "AuthInputsPasswordBasedView.h"

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
    
    // Setup `MXKAuthenticationViewController` properties
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    self.mainNavigationItem.title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    self.rightBarButtonItem.title = NSLocalizedStringFromTable(@"auth_register", @"Vector", nil);
    
    self.defaultHomeServerUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"homeserverurl"];
    self.homeServerTextField.textColor = VECTOR_TEXT_GRAY_COLOR;
    self.homeServerLabel.textColor = VECTOR_TEXT_BLACK_COLOR;
    
    self.defaultIdentityServerUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"identityserverurl"];
    self.identityServerTextField.textColor = VECTOR_TEXT_GRAY_COLOR;
    self.identityServerLabel.textColor = VECTOR_TEXT_BLACK_COLOR;
    
    self.welcomeImageView.image = [UIImage imageNamed:@"logo"];
    
    [self.submitButton.layer setCornerRadius:5];
    self.submitButton.clipsToBounds = YES;
    self.submitButton.backgroundColor = VECTOR_GREEN_COLOR;
    [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_login", @"Vector", nil) forState:UIControlStateNormal];
    [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_login", @"Vector", nil) forState:UIControlStateHighlighted];
    
    [self.forgotPasswordButton setTitle:NSLocalizedStringFromTable(@"auth_forgot_password", @"Vector", nil) forState:UIControlStateNormal];
    [self.forgotPasswordButton setTitle:NSLocalizedStringFromTable(@"auth_forgot_password", @"Vector", nil) forState:UIControlStateHighlighted];
    [self.forgotPasswordButton setTitleColor:VECTOR_TEXT_GRAY_COLOR forState:UIControlStateNormal];
    [self.forgotPasswordButton setTitleColor:VECTOR_TEXT_GRAY_COLOR forState:UIControlStateHighlighted];
    
    [self.serverOptionsTickButton setImage:[UIImage imageNamed:@"untick"] forState:UIControlStateNormal];
    [self.serverOptionsTickButton setImage:[UIImage imageNamed:@"untick"] forState:UIControlStateHighlighted];
    
    NSAttributedString *serverOptionsTitle = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"auth_use_server_options", @"Vector", nil) attributes:@{NSForegroundColorAttributeName : VECTOR_TEXT_GRAY_COLOR, NSFontAttributeName: [UIFont systemFontOfSize:14]}];
    [self.serverOptionsTickButton setAttributedTitle:serverOptionsTitle forState:UIControlStateNormal];
    [self.serverOptionsTickButton setAttributedTitle:serverOptionsTitle forState:UIControlStateHighlighted];
    
    [self hideServerOptionsContainer:YES];
    
    // The view controller dismiss itself on successful login.
    self.delegate = self;
    
    // Custom used authInputsView
    [self registerAuthInputsViewClass:AuthInputsPasswordBasedView.class forFlowType:kMXLoginFlowTypePassword andAuthType:MXKAuthenticationTypeLogin];
    [self registerAuthInputsViewClass:AuthInputsPasswordBasedView.class forFlowType:kMXLoginFlowTypeEmailIdentity andAuthType:MXKAuthenticationTypeRegister];
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
    
    // Update supported authentication flow
    [self refreshSupportedAuthFlow];
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
            self.forgotPasswordButton.hidden = YES;
        }
        else
        {
            self.authType = MXKAuthenticationTypeLogin;
            self.rightBarButtonItem.title = NSLocalizedStringFromTable(@"auth_register", @"Vector", nil);
            self.forgotPasswordButton.hidden = NO;
        }
        
        [self hideServerOptionsContainer:YES];
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
        
        [self.serverOptionsTickButton setImage:[UIImage imageNamed:@"untick"] forState:UIControlStateNormal];
        self.serverOptionsContainer.hidden = YES;
        
        // Refresh content view height
        self.contentViewHeightConstraint.constant -= self.serverOptionsContainer.frame.size.height;
    }
    else
    {
        [self.serverOptionsTickButton setImage:[UIImage imageNamed:@"tick"] forState:UIControlStateNormal];
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
    // Report server url typed by the user as default url.
    if (self.homeServerTextField.text.length)
    {
        [[NSUserDefaults standardUserDefaults] setObject:self.homeServerTextField.text forKey:@"homeserverurl"];
    }
    if (self.identityServerTextField.text.length)
    {
        [[NSUserDefaults standardUserDefaults] setObject:self.identityServerTextField.text forKey:@"identityserverurl"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
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
