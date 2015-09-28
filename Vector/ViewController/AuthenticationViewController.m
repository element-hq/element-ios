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

#import "AuthInputsEmailIdentityBasedView.h"

#import "RageShakeManager.h"

@implementation AuthenticationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup `MXKAuthenticationViewController` properties
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    self.defaultHomeServerUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"homeserverurl"];
    self.defaultIdentityServerUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"identityserverurl"];
    
    // Load welcome image from MatrixKit asset bundle
    self.welcomeImageView.image = [UIImage imageNamed:@"logo"];
    
    self.subTitleLabel.hidden = NO;
    
    // The view controller dismiss itself on successful login.
    self.delegate = self;
    
    // Custom used authInputsView
    [self registerAuthInputsViewClass:AuthInputsEmailIdentityBasedView.class forFlowType:kMXLoginFlowTypeEmailIdentity andAuthType:MXKAuthenticationTypeRegister];
}

- (void)setAuthType:(MXKAuthenticationType)authType
{
    super.authType = authType;
    self.subTitleLabel.hidden = NO;
    
    if (authType == MXKAuthenticationTypeLogin)
    {
        self.subTitleLabel.text = NSLocalizedStringFromTable(@"auth_sign_in", @"Vector", nil);
        
        [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_login", @"Vector", nil) forState:UIControlStateNormal];
        [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_login", @"Vector", nil) forState:UIControlStateHighlighted];
        [self.authSwitchButton setTitle:NSLocalizedStringFromTable(@"auth_create_account", @"Vector", nil) forState:UIControlStateNormal];
        [self.authSwitchButton setTitle:NSLocalizedStringFromTable(@"auth_create_account", @"Vector", nil) forState:UIControlStateHighlighted];
    }
    else
    {
        self.subTitleLabel.text = NSLocalizedStringFromTable(@"auth_create_account_title", @"Vector", nil);
        
        [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_register", @"Vector", nil) forState:UIControlStateNormal];
        [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_register", @"Vector", nil) forState:UIControlStateHighlighted];
        [self.authSwitchButton setTitle:NSLocalizedStringFromTable(@"auth_back_to_login", @"Vector", nil) forState:UIControlStateNormal];
        [self.authSwitchButton setTitle:NSLocalizedStringFromTable(@"auth_back_to_login", @"Vector", nil) forState:UIControlStateHighlighted];
    }
    
    // Update supported authentication flow
    [self refreshSupportedAuthFlow];
}

#pragma mark - MXKAuthenticationViewControllerDelegate

- (void)authenticationViewController:(MXKAuthenticationViewController *)authenticationViewController didLogWithUserId:(NSString *)userId {
    
    // Report server url typed by the user as default url.
    if (self.homeServerTextField.text.length) {
        [[NSUserDefaults standardUserDefaults] setObject:self.homeServerTextField.text forKey:@"homeserverurl"];
    }
    if (self.identityServerTextField.text.length) {
        [[NSUserDefaults standardUserDefaults] setObject:self.identityServerTextField.text forKey:@"identityserverurl"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Remove auth view controller on successful login
    if (self.navigationController) {
        // Pop the view controller
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        // Dismiss on successful login
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
}

@end
