/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 Copyright 2019 New Vector Ltd

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
#import "Riot-Swift.h"

#import "AuthInputsView.h"
#import "ForgotPasswordInputsView.h"
#import "AuthFallBackViewController.h"

@interface AuthenticationViewController () <AuthFallBackViewControllerDelegate>
{
    /**
     Store the potential login error received by using a default homeserver different from matrix.org
     while we retry a login process against the matrix.org HS.
     */
    NSError *loginError;
    
    /**
     The default country code used to initialize the mobile phone number input.
     */
    NSString *defaultCountryCode;
    
    /**
     Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
     */
    id kThemeServiceDidChangeThemeNotificationObserver;

    /**
     Server discovery.
     */
    MXAutoDiscovery *autoDiscovery;

    AuthFallBackViewController *authFallBackViewController;
}

@property (nonatomic, readonly) BOOL isIdentityServerConfigured;

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
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // Set a default country code
    // Note: this value is used only when no MCC and no local country code is available.
    defaultCountryCode = @"GB";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mainNavigationItem.title = nil;
    self.rightBarButtonItem.title = NSLocalizedStringFromTable(@"auth_register", @"Vector", nil);
    
    self.defaultHomeServerUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"homeserverurl"];
    
    self.defaultIdentityServerUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"identityserverurl"];
    
    self.welcomeImageView.image = [UIImage imageNamed:@"logo"];
    
    [self.submitButton.layer setCornerRadius:5];
    self.submitButton.clipsToBounds = YES;
    [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_login", @"Vector", nil) forState:UIControlStateNormal];
    [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_login", @"Vector", nil) forState:UIControlStateHighlighted];
    self.submitButton.enabled = YES;
    
    [self.skipButton.layer setCornerRadius:5];
    self.skipButton.clipsToBounds = YES;
    [self.skipButton setTitle:NSLocalizedStringFromTable(@"auth_skip", @"Vector", nil) forState:UIControlStateNormal];
    [self.skipButton setTitle:NSLocalizedStringFromTable(@"auth_skip", @"Vector", nil) forState:UIControlStateHighlighted];
    self.skipButton.enabled = YES;
    
    [self.customServersTickButton setImage:[UIImage imageNamed:@"selection_untick"] forState:UIControlStateNormal];
    [self.customServersTickButton setImage:[UIImage imageNamed:@"selection_untick"] forState:UIControlStateHighlighted];
    
    [self hideCustomServers:YES];

    // Soft logout section
    self.softLogoutClearDataButton.layer.cornerRadius = 5;
    self.softLogoutClearDataButton.clipsToBounds = YES;
    [self.softLogoutClearDataButton setTitle:NSLocalizedStringFromTable(@"auth_softlogout_clear_data_button", @"Vector", nil) forState:UIControlStateNormal];
    [self.softLogoutClearDataButton setTitle:NSLocalizedStringFromTable(@"auth_softlogout_clear_data_button", @"Vector", nil) forState:UIControlStateHighlighted];
    self.softLogoutClearDataButton.enabled = YES;
    self.softLogoutClearDataContainer.hidden = YES;
    
    // The view controller dismiss itself on successful login.
    self.delegate = self;
    
    self.homeServerTextField.placeholder = NSLocalizedStringFromTable(@"auth_home_server_placeholder", @"Vector", nil);
    self.identityServerTextField.placeholder = NSLocalizedStringFromTable(@"auth_identity_server_placeholder", @"Vector", nil);
    
    // Custom used authInputsView
    [self registerAuthInputsViewClass:AuthInputsView.class forAuthType:MXKAuthenticationTypeLogin];
    [self registerAuthInputsViewClass:AuthInputsView.class forAuthType:MXKAuthenticationTypeRegister];
    [self registerAuthInputsViewClass:ForgotPasswordInputsView.class forAuthType:MXKAuthenticationTypeForgotPassword];
    
    // Initialize the auth inputs display
    AuthInputsView *authInputsView = [AuthInputsView authInputsView];
    MXAuthenticationSession *authSession = [MXAuthenticationSession modelFromJSON:@{@"flows":@[@{@"stages":@[kMXLoginFlowTypePassword]}]}];
    [authInputsView setAuthSession:authSession withAuthType:MXKAuthenticationTypeLogin];
    self.authInputsView = authInputsView;

    // Listen to action within the child view
    [authInputsView.ssoButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationBar];
    self.navigationBarSeparatorView.backgroundColor = ThemeService.shared.theme.lineBreakColor;

    // This view controller is not part of a navigation controller
    // so that applyStyleOnNavigationBar does not fully work.
    // In order to have the right status bar color, use the expected status bar color
    // as the main view background color.
    // Hopefully, subviews define their own background color with `theme.backgroundColor`,
    // which makes all work together.
    self.view.backgroundColor = ThemeService.shared.theme.baseColor;

    self.authenticationScrollView.backgroundColor = ThemeService.shared.theme.backgroundColor;

    // Style the authentication fallback webview screen so that its header matches to navigation bar style
    self.authFallbackContentView.backgroundColor = ThemeService.shared.theme.baseColor;
    self.cancelAuthFallbackButton.tintColor = ThemeService.shared.theme.baseTextPrimaryColor;

    if (self.homeServerTextField.placeholder)
    {
        self.homeServerTextField.attributedPlaceholder = [[NSAttributedString alloc]
                                                          initWithString:self.homeServerTextField.placeholder
                                                          attributes:@{NSForegroundColorAttributeName: ThemeService.shared.theme.placeholderTextColor}];
    }
    if (self.identityServerTextField.placeholder)
    {
        self.identityServerTextField.attributedPlaceholder = [[NSAttributedString alloc]
                                                              initWithString:self.identityServerTextField.placeholder
                                                              attributes:@{NSForegroundColorAttributeName: ThemeService.shared.theme.placeholderTextColor}];
    }
    
    self.submitButton.backgroundColor = ThemeService.shared.theme.tintColor;
    self.skipButton.backgroundColor = ThemeService.shared.theme.tintColor;
    
    self.noFlowLabel.textColor = ThemeService.shared.theme.warningColor;
    
    NSMutableAttributedString *forgotPasswordTitle = [[NSMutableAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"auth_forgot_password", @"Vector", nil)];
    [forgotPasswordTitle addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, forgotPasswordTitle.length)];
    [forgotPasswordTitle addAttribute:NSForegroundColorAttributeName value:ThemeService.shared.theme.tintColor range:NSMakeRange(0, forgotPasswordTitle.length)];
    [self.forgotPasswordButton setAttributedTitle:forgotPasswordTitle forState:UIControlStateNormal];
    [self.forgotPasswordButton setAttributedTitle:forgotPasswordTitle forState:UIControlStateHighlighted];
    
    NSMutableAttributedString *forgotPasswordTitleDisabled = [[NSMutableAttributedString alloc] initWithAttributedString:forgotPasswordTitle];
    [forgotPasswordTitleDisabled addAttribute:NSForegroundColorAttributeName value:[ThemeService.shared.theme.tintColor colorWithAlphaComponent:0.3] range:NSMakeRange(0, forgotPasswordTitle.length)];
    [self.forgotPasswordButton setAttributedTitle:forgotPasswordTitleDisabled forState:UIControlStateDisabled];
    
    [self updateForgotPwdButtonVisibility];
    
    NSAttributedString *serverOptionsTitle = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"auth_use_server_options", @"Vector", nil) attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.textSecondaryColor, NSFontAttributeName: [UIFont systemFontOfSize:14]}];
    [self.customServersTickButton setAttributedTitle:serverOptionsTitle forState:UIControlStateNormal];
    [self.customServersTickButton setAttributedTitle:serverOptionsTitle forState:UIControlStateHighlighted];
    
    self.homeServerSeparator.backgroundColor = ThemeService.shared.theme.lineBreakColor;
    self.homeServerTextField.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.homeServerLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
    
    self.identityServerSeparator.backgroundColor = ThemeService.shared.theme.lineBreakColor;
    self.identityServerTextField.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.identityServerLabel.textColor = ThemeService.shared.theme.textSecondaryColor;

    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;

    self.softLogoutClearDataLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.softLogoutClearDataButton.backgroundColor = ThemeService.shared.theme.warningColor;

    [self.authInputsView customizeViewRendering];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Screen tracking
    [[Analytics sharedInstance] trackScreen:@"Authentication"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Verify that the app does not show the authentification screean whereas
    // the user has already logged in.
    // This bug rarely happens (https://github.com/vector-im/riot-ios/issues/1643)
    // but it invites the user to log in again. They will then lose all their
    // e2e messages.
    NSLog(@"[AuthenticationVC] viewDidAppear: Checking false logout");
    [[MXKAccountManager sharedManager] forceReloadAccounts];
    if ([MXKAccountManager sharedManager].activeAccounts.count)
    {
        // For now, we do not have better solution than forcing the user to restart the app
        [NSException raise:@"False logout. Kill the app" format:@"AuthenticationViewController has been displayed whereas there is an existing account"];
    }
}

- (void)destroy
{
    [super destroy];
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }

    autoDiscovery = nil;
}

- (BOOL)isIdentityServerConfigured
{
    return self.identityServerTextField.text.length > 0;
}

- (void)setAuthType:(MXKAuthenticationType)authType
{
    if (self.authType == MXKAuthenticationTypeRegister)
    {
        // Restore the default registration screen
        [self updateRegistrationScreenWithThirdPartyIdentifiersHidden:YES];
    }
    
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
    [self updateSoftLogoutClearDataContainerVisibility];
}

- (void)setAuthInputsView:(MXKAuthInputsView *)authInputsView
{
    // Keep the current country code if any.
    if ([self.authInputsView isKindOfClass:AuthInputsView.class])
    {
        // We will reuse the current country code
        defaultCountryCode = ((AuthInputsView*)self.authInputsView).isoCountryCode;
    }
    
    // Finalize the new auth inputs view
    if ([authInputsView isKindOfClass:AuthInputsView.class])
    {
        AuthInputsView *authInputsview = (AuthInputsView*)authInputsView;
        
        // Retrieve the MCC from the SIM card information (Note: the phone book country code is not defined yet)
        NSString *countryCode = [MXKAppSettings standardAppSettings].phonebookCountryCode;
        if (!countryCode)
        {
            // If none, consider the preferred locale
            NSLocale *local = [[NSLocale alloc] initWithLocaleIdentifier:[[NSBundle mainBundle] preferredLocalizations][0]];
            if ([local respondsToSelector:@selector(countryCode)])
            {
                countryCode = local.countryCode;
            }
            
            if (!countryCode)
            {
                countryCode = defaultCountryCode;
            }
        }
        authInputsview.isoCountryCode = countryCode;
        authInputsview.delegate = self;
    }
    
    [super setAuthInputsView:authInputsView];
    
    // Restore here the actual content view height.
    // Indeed this height has been modified according to the authInputsView height in the default implementation of MXKAuthenticationViewController.
    [self refreshContentViewHeightConstraint];
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled
{
    super.userInteractionEnabled = userInteractionEnabled;

    // Reset
    self.rightBarButtonItem.enabled = YES;
    
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

        // Remove the potential back button.
        self.mainNavigationItem.leftBarButtonItem = nil;
    }
    else
    {
        AuthInputsView *authInputsview;
        if ([self.authInputsView isKindOfClass:AuthInputsView.class])
        {
            authInputsview = (AuthInputsView*)self.authInputsView;
        }

        // The right bar button is used to switch the authentication type.
        if (self.authType == MXKAuthenticationTypeLogin)
        {
            if (!authInputsview.isSingleSignOnRequired && !self.softLogoutCredentials)
            {
                self.rightBarButtonItem.title = NSLocalizedStringFromTable(@"auth_register", @"Vector", nil);
            }
            else
            {
                // Disable register on SSO
                self.rightBarButtonItem.enabled = NO;
                self.rightBarButtonItem.title = nil;
            }
        }
        else if (self.authType == MXKAuthenticationTypeRegister)
        {
            self.rightBarButtonItem.title = NSLocalizedStringFromTable(@"auth_login", @"Vector", nil);
            
            // Restore the back button
            if (authInputsview)
            {
                [self updateRegistrationScreenWithThirdPartyIdentifiersHidden:authInputsview.thirdPartyIdentifiersHidden];
            }
        }
        else if (self.authType == MXKAuthenticationTypeForgotPassword)
        {
            // The right bar button is used to return to login.
            self.rightBarButtonItem.title = NSLocalizedStringFromTable(@"cancel", @"Vector", nil);
        }
    }
}


#pragma mark - Fallback URL display

- (void)showAuthenticationFallBackView:(NSString*)fallbackPage
{
    // Skip MatrixKit and use a VC instead
    if (self.softLogoutCredentials)
    {
        // Add device_id as query param of the fallback
        NSURLComponents *components = [[NSURLComponents alloc] initWithString:fallbackPage];

        NSMutableArray<NSURLQueryItem*> *queryItems = [components.queryItems mutableCopy];
        if (!queryItems)
        {
            queryItems = [NSMutableArray array];
        }

        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"device_id"
                                                          value:self.softLogoutCredentials.deviceId]];

        components.queryItems = queryItems;

        fallbackPage = components.URL.absoluteString;
    }

    [self showAuthenticationFallBackViewController:fallbackPage];
}

- (void)showAuthenticationFallBackViewController:(NSString*)fallbackPage
{
    authFallBackViewController = [[AuthFallBackViewController alloc] initWithURL:fallbackPage];
    authFallBackViewController.delegate = self;


    authFallBackViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissFallBackViewController:)];

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:authFallBackViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)dismissFallBackViewController:(id)sender
{
    [authFallBackViewController dismissViewControllerAnimated:YES completion:nil];
    authFallBackViewController = nil;
}


#pragma mark AuthFallBackViewControllerDelegate

- (void)authFallBackViewController:(AuthFallBackViewController *)authFallBackViewController
         didLoginWithLoginResponse:(MXLoginResponse *)loginResponse
{
    [authFallBackViewController dismissViewControllerAnimated:YES completion:^{
        
        MXCredentials *credentials = [[MXCredentials alloc] initWithLoginResponse:loginResponse andDefaultCredentials:nil];
        [self onSuccessfulLogin:credentials];
    }];

    authFallBackViewController = nil;
}


- (void)authFallBackViewControllerDidClose:(AuthFallBackViewController *)authFallBackViewController
{
    [self dismissFallBackViewController:nil];
}


- (void)setSoftLogoutCredentials:(MXCredentials *)softLogoutCredentials
{
    [super setSoftLogoutCredentials:softLogoutCredentials];

    // Customise the screen for soft logout
    self.customServersTickButton.hidden = YES;
    self.rightBarButtonItem.title = nil;
    self.mainNavigationItem.title = NSLocalizedStringFromTable(@"auth_softlogout_signed_out", @"Vector", nil);

    [self showSoftLogoutClearDataContainer];
}

- (void)showSoftLogoutClearDataContainer
{
    NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"auth_softlogout_clear_data", @"Vector", nil)
                                                                                attributes:@{
                                                                                             NSFontAttributeName: [UIFont boldSystemFontOfSize:14]
                                                                                             }];

    [message appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n"]];

    NSString *string = [NSString stringWithFormat:@"%@\n\n%@",
                        NSLocalizedStringFromTable(@"auth_softlogout_clear_data_message_1", @"Vector", nil),
                        NSLocalizedStringFromTable(@"auth_softlogout_clear_data_message_2", @"Vector", nil)];
    
    [message appendAttributedString:[[NSAttributedString alloc] initWithString:string
                                                                    attributes:@{
                                                                                 NSFontAttributeName: [UIFont systemFontOfSize:14]
                                                                                 }]];
    self.softLogoutClearDataLabel.attributedText = message;

    self.softLogoutClearDataContainer.hidden = NO;
    [self refreshContentViewHeightConstraint];
}

- (void)updateSoftLogoutClearDataContainerVisibility
{
    // Do not display it in case of forget password flow
    if (self.softLogoutCredentials && self.authType == MXKAuthenticationTypeLogin)
    {
        self.softLogoutClearDataContainer.hidden = NO;
    }
    else
    {
        self.softLogoutClearDataContainer.hidden = YES;
    }
}

- (void)showClearDataAfterSoftLogoutConfirmation
{
    // Request confirmation
    if (alert)
    {
        [alert dismissViewControllerAnimated:NO completion:nil];
    }

    alert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"auth_softlogout_clear_data_sign_out_title", @"Vector", nil)
                                                message:NSLocalizedStringFromTable(@"auth_softlogout_clear_data_sign_out_msg", @"Vector", nil)
                                         preferredStyle:UIAlertControllerStyleAlert];


    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"auth_softlogout_clear_data_sign_out", @"Vector", nil)                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action)
                      {
                          [self clearDataAfterSoftLogout];
                      }]];

    MXWeakify(self);
    [alert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action)
                      {
                          MXStrongifyAndReturnIfNil(self);
                          self->alert = nil;
                      }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)clearDataAfterSoftLogout
{
    NSLog(@"[AuthenticationVC] clearDataAfterSoftLogout %@", self.softLogoutCredentials.userId);

    // Use AppDelegate so that we reset app settings and this auth screen
    [[AppDelegate theDelegate] logoutSendingRequestServer:YES completion:^(BOOL isLoggedOut) {
        NSLog(@"[AuthenticationVC] Complete. isLoggedOut: %@", @(isLoggedOut));
    }];
}

/**
 Filter and prioritise flows supported by the app.

 @param authSession the auth session coming from the HS.
 @return a new auth session
 */
- (MXAuthenticationSession*)handleSupportedFlowsInAuthenticationSession:(MXAuthenticationSession *)authSession
{
    MXLoginFlow *ssoFlow;
    NSMutableArray *supportedFlows = [NSMutableArray array];

    for (MXLoginFlow *flow in authSession.flows)
    {
        // Remove known flows we do not support
        if (![flow.type isEqualToString:kMXLoginFlowTypeToken])
        {
            NSLog(@"[AuthenticationVC] handleSupportedFlowsInAuthenticationSession: Filter out flow %@", flow.type);
            [supportedFlows addObject:flow];
        }

        // Prioritise SSO over other flows
        if ([flow.type isEqualToString:kMXLoginFlowTypeSSO]
            || [flow.type isEqualToString:kMXLoginFlowTypeCAS])
        {
            NSLog(@"[AuthenticationVC] handleSupportedFlowsInAuthenticationSession: Prioritise flow %@", flow.type);
            ssoFlow = flow;
            break;
        }
    }

    if (ssoFlow)
    {
        [supportedFlows removeAllObjects];
        [supportedFlows addObject:ssoFlow];
    }

    if (supportedFlows.count != authSession.flows.count)
    {
        MXAuthenticationSession *updatedAuthSession = [[MXAuthenticationSession alloc] init];
        updatedAuthSession.session = authSession.session;
        updatedAuthSession.params = authSession.params;
        updatedAuthSession.flows = supportedFlows;
        return updatedAuthSession;
    }
    else
    {
        return authSession;
    }
}

- (void)handleAuthenticationSession:(MXAuthenticationSession *)authSession
{
    // Make some cleaning from the server response according to what the app supports
    authSession = [self handleSupportedFlowsInAuthenticationSession:authSession];
    
    [super handleAuthenticationSession:authSession];

    AuthInputsView *authInputsview;
    if ([self.authInputsView isKindOfClass:AuthInputsView.class])
    {
        authInputsview = (AuthInputsView*)self.authInputsView;
    }

    // Hide "Forgot password" and "Log in" buttons in case of SSO
    [self updateForgotPwdButtonVisibility];
    [self updateSoftLogoutClearDataContainerVisibility];

    self.submitButton.hidden = authInputsview.isSingleSignOnRequired;

    // Bind ssoButton again if self.authInputsView has changed
    [authInputsview.ssoButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    if (authInputsview.isSingleSignOnRequired && self.softLogoutCredentials)
    {
        // Remove submitButton so that the 2nd contraint on softLogoutClearDataContainer.top will be applied
        // That makes softLogoutClearDataContainer appear upper in the screen
        [self.submitButton removeFromSuperview];
    }
}

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == self.customServersTickButton)
    {
        [self hideCustomServers:!self.customServersContainer.hidden];
    }
    else if (sender == self.forgotPasswordButton)
    {
        if (!self.isIdentityServerConfigured)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSBundle mxk_localizedStringForKey:@"error"]
                                                                           message:NSLocalizedStringFromTable(@"auth_forgot_password_error_no_configured_identity_server", @"Vector", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            
            return;
        }
        else
        {
            // Update UI to reset password
            self.authType = MXKAuthenticationTypeForgotPassword;
        }
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
    else if (sender == self.mainNavigationItem.leftBarButtonItem)
    {
        if ([self.authInputsView isKindOfClass:AuthInputsView.class])
        {
            AuthInputsView *authInputsview = (AuthInputsView*)self.authInputsView;
            
            // Hide the supported 3rd party ids which may be added to the account
            authInputsview.thirdPartyIdentifiersHidden = YES;
            
            [self updateRegistrationScreenWithThirdPartyIdentifiersHidden:YES];
        }
    }
    else if (sender == self.submitButton)
    {
        // Handle here the second screen used to manage the 3rd party ids during the registration.
        // Except if there is an external set of parameters defined to perform a registration.
        if (self.authType == MXKAuthenticationTypeRegister && !self.externalRegistrationParameters)
        {
            // Sanity check
            if ([self.authInputsView isKindOfClass:AuthInputsView.class])
            {
                AuthInputsView *authInputsview = (AuthInputsView*)self.authInputsView;
                
                // Show the 3rd party ids screen if it is not shown yet
                if (authInputsview.areThirdPartyIdentifiersSupported && authInputsview.isThirdPartyIdentifiersHidden)
                {
                    [self dismissKeyboard];
                    
                    [self.authenticationActivityIndicator startAnimating];
                    
                    // Check parameters validity
                    NSString *errorMsg = [self.authInputsView validateParameters];
                    if (errorMsg)
                    {
                        [self onFailureDuringAuthRequest:[NSError errorWithDomain:MXKAuthErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:errorMsg}]];
                    }
                    else
                    {
                        [self testUserRegistration:^(MXError *mxError) {
                            // We consider that a user can be registered if:
                            //   - the username is not already in use
                            if ([mxError.errcode isEqualToString:kMXErrCodeStringUserInUse])
                            {
                                NSLog(@"[AuthenticationVC] User name is already use");
                                [self onFailureDuringAuthRequest:[NSError errorWithDomain:MXKAuthErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:[NSBundle mxk_localizedStringForKey:@"auth_username_in_use"]}]];
                            }
                            //   - the server quota limits is not reached
                            else if ([mxError.errcode isEqualToString:kMXErrCodeStringResourceLimitExceeded])
                            {
                                [self showResourceLimitExceededError:mxError.userInfo];
                            }
                            else
                            {
                                [self.authenticationActivityIndicator stopAnimating];

                                // Show the supported 3rd party ids which may be added to the account
                                authInputsview.thirdPartyIdentifiersHidden = NO;
                                [self updateRegistrationScreenWithThirdPartyIdentifiersHidden:NO];
                            }
                        }];
                    }
                    
                    return;
                }
            }
        }
        
        [super onButtonPressed:sender];
    }
    else if (sender == self.skipButton)
    {
        // Reset the potential email or phone values
        if ([self.authInputsView isKindOfClass:AuthInputsView.class])
        {
            AuthInputsView *authInputsview = (AuthInputsView*)self.authInputsView;
            
            [authInputsview resetThirdPartyIdentifiers];
        }
        
        [super onButtonPressed:self.submitButton];
    }
    else if (sender == ((AuthInputsView*)self.authInputsView).ssoButton)
    {
        // Do SSO using the fallback URL
        [self showAuthenticationFallBackView];
    }
    else if (sender == self.softLogoutClearDataButton)
    {
        [self showClearDataAfterSoftLogoutConfirmation];
    }
    else
    {
        [super onButtonPressed:sender];
    }

    [self updateSoftLogoutClearDataContainerVisibility];
}

- (void)onFailureDuringAuthRequest:(NSError *)error
{
    // Homeserver migration: When the default homeserver url is different from matrix.org,
    // the login (or forgot pwd) process with an existing matrix.org accounts will then fail.
    // Patch: Falling back to matrix.org HS so we don't break everyone's logins
    if ([self.homeServerTextField.text isEqualToString:self.defaultHomeServerUrl] && ![self.defaultHomeServerUrl isEqualToString:@"https://matrix.org"] && !self.softLogoutCredentials)
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
        MXError *mxError = [[MXError alloc] initWithNSError:error];
        if ([mxError.errcode isEqualToString:kMXErrCodeStringResourceLimitExceeded])
        {
            [self showResourceLimitExceededError:mxError.userInfo];
        }
        else
        {
            [super onFailureDuringAuthRequest:error];
        }
    }
}

- (void)onSuccessfulLogin:(MXCredentials*)credentials
{
    // Check whether a third party identifiers has not been used
    if ([self.authInputsView isKindOfClass:AuthInputsView.class])
    {
        AuthInputsView *authInputsview = (AuthInputsView*)self.authInputsView;
        if (authInputsview.isThirdPartyIdentifierPending)
        {
            // Alert user
            if (alert)
            {
                [alert dismissViewControllerAnimated:NO completion:nil];
            }
            
            alert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"warning", @"Vector", nil) message:NSLocalizedStringFromTable(@"auth_add_email_and_phone_warning", @"Vector", nil) preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               [super onSuccessfulLogin:credentials];
                                                               
                                                           }]];
            
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
    }
    
    [super onSuccessfulLogin:credentials];
}

- (void)updateForgotPwdButtonVisibility
{
    AuthInputsView *authInputsview;
    if ([self.authInputsView isKindOfClass:AuthInputsView.class])
    {
        authInputsview = (AuthInputsView*)self.authInputsView;
    }

    self.forgotPasswordButton.hidden = (self.authType != MXKAuthenticationTypeLogin) || authInputsview.isSingleSignOnRequired;
    
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

- (void)updateRegistrationScreenWithThirdPartyIdentifiersHidden:(BOOL)thirdPartyIdentifiersHidden
{
    self.skipButton.hidden = thirdPartyIdentifiersHidden;
    
    self.serverOptionsContainer.hidden = !thirdPartyIdentifiersHidden;
    [self refreshContentViewHeightConstraint];
    
    if (thirdPartyIdentifiersHidden)
    {
        [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_register", @"Vector", nil) forState:UIControlStateNormal];
        [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_register", @"Vector", nil) forState:UIControlStateHighlighted];
        
        self.mainNavigationItem.leftBarButtonItem = nil;
    }
    else
    {
        [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_submit", @"Vector", nil) forState:UIControlStateNormal];
        [self.submitButton setTitle:NSLocalizedStringFromTable(@"auth_submit", @"Vector", nil) forState:UIControlStateHighlighted];
        
        UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back_icon"] style:UIBarButtonItemStylePlain target:self action:@selector(onButtonPressed:)];
        self.mainNavigationItem.leftBarButtonItem = leftBarButtonItem;
    }
}

- (void)refreshContentViewHeightConstraint
{
    // Refresh content view height by considering the options container display.
    CGFloat constant = self.optionsContainer.frame.origin.y + 10;
    
    if (!self.optionsContainer.isHidden)
    {
        constant += self.serverOptionsContainer.frame.origin.y;
        
        if (!self.serverOptionsContainer.isHidden)
        {
            CGRect customServersContainerFrame = self.customServersContainer.frame;
            constant += customServersContainerFrame.origin.y;
            
            if (!self.customServersContainer.isHidden)
            {
                constant += customServersContainerFrame.size.height;
            }
        }
    }

    if (!self.softLogoutClearDataContainer.isHidden)
    {
        // The soft logout clear data section adds more height
        constant += self.softLogoutClearDataContainer.frame.size.height;
    }

    self.contentViewHeightConstraint.constant = constant;
}

- (void)hideCustomServers:(BOOL)hidden
{
    if (self.customServersContainer.isHidden == hidden)
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
                
        // Restore default configuration
        [self setHomeServerTextFieldText:self.defaultHomeServerUrl];
        [self setIdentityServerTextFieldText:self.defaultIdentityServerUrl];
        
        [self.customServersTickButton setImage:[UIImage imageNamed:@"selection_untick"] forState:UIControlStateNormal];
        self.customServersContainer.hidden = YES;
        
        // Refresh content view height
        self.contentViewHeightConstraint.constant -= self.customServersContainer.frame.size.height;
    }
    else
    {
        // Load custom configuration
        NSString *customHomeServerURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"customHomeServerURL"];
        if (customHomeServerURL.length)
        {
            [self setHomeServerTextFieldText:customHomeServerURL];
        }
        else
        {
            [self checkIdentityServer];
        }
        NSString *customIdentityServerURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"customIdentityServerURL"];
        if (customIdentityServerURL.length)
        {
            [self setIdentityServerTextFieldText:customIdentityServerURL];
        }
        
        [self.customServersTickButton setImage:[UIImage imageNamed:@"selection_tick"] forState:UIControlStateNormal];
        self.customServersContainer.hidden = NO;
        
        // Refresh content view height
        self.contentViewHeightConstraint.constant += self.customServersContainer.frame.size.height;

        // Scroll to display server options
        CGPoint offset = self.authenticationScrollView.contentOffset;
        offset.y += self.customServersContainer.frame.size.height;
        self.authenticationScrollView.contentOffset = offset;
    }
}

- (void)showResourceLimitExceededError:(NSDictionary *)errorDict
{
    NSLog(@"[AuthenticationVC] showResourceLimitExceededError");

    [self showResourceLimitExceededError:errorDict onAdminContactTapped:^(NSURL *adminContact) {

        if ([[UIApplication sharedApplication] canOpenURL:adminContact])
        {
            [[UIApplication sharedApplication] openURL:adminContact];
        }
        else
        {
            NSLog(@"[AuthenticationVC] adminContact(%@) cannot be opened", adminContact);
        }
    }];
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
    // Hide the custom server details in order to save customized inputs
    [self hideCustomServers:YES];
    
    // Create DM with Riot-bot on new account creation.
    if (self.authType == MXKAuthenticationTypeRegister)
    {
        MXKAccount *account = [[MXKAccountManager sharedManager] accountForUserId:userId];
        
        [account.mxSession createRoom:nil
                           visibility:kMXRoomDirectoryVisibilityPrivate
                            roomAlias:nil
                                topic:nil
                               invite:@[@"@riot-bot:matrix.org"]
                           invite3PID:nil
                             isDirect:YES
                               preset:kMXRoomPresetTrustedPrivateChat
                              success:nil
                              failure:^(NSError *error) {
                                  
                                  NSLog(@"[AuthenticationVC] Create chat with riot-bot failed");
                                  
                              }];
    }
    
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

#pragma mark - MXKAuthInputsViewDelegate

- (void)authInputsView:(MXKAuthInputsView *)authInputsView presentViewController:(UIViewController*)viewControllerToPresent animated:(BOOL)animated
{
    [self dismissKeyboard];
    [self presentViewController:viewControllerToPresent animated:animated completion:nil];
}

- (void)authInputsViewDidCancelOperation:(MXKAuthInputsView *)authInputsView
{
    [self cancel];
}

- (void)authInputsView:(MXKAuthInputsView *)authInputsView autoDiscoverServerWithDomain:(NSString *)domain
{
    [self tryServerDiscoveryOnDomain:domain];
}

#pragma mark - Server discovery

- (void)tryServerDiscoveryOnDomain:(NSString *)domain
{
    autoDiscovery = [[MXAutoDiscovery alloc] initWithDomain:domain];

    MXWeakify(self);
    [autoDiscovery findClientConfig:^(MXDiscoveredClientConfig * _Nonnull discoveredClientConfig) {
        MXStrongifyAndReturnIfNil(self);

        self->autoDiscovery = nil;

        switch (discoveredClientConfig.action)
        {
            case MXDiscoveredClientConfigActionPrompt:
                [self customiseServersWithWellKnown:discoveredClientConfig.wellKnown];
                break;

            case MXDiscoveredClientConfigActionFailPrompt:
            case MXDiscoveredClientConfigActionFailError:
            {
                // Alert user
                if (self->alert)
                {
                    [self->alert dismissViewControllerAnimated:NO completion:nil];
                }

                self->alert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"auth_autodiscover_invalid_response", @"Vector", nil)
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleAlert];

                [self->alert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {

                                                                  self->alert = nil;
                                                              }]];

                [self presentViewController:self->alert animated:YES completion:nil];

                break;
            }

            default:
                // Fail silently
                break;
        }

    } failure:^(NSError * _Nonnull error) {
        MXStrongifyAndReturnIfNil(self);

        self->autoDiscovery = nil;

        // Fail silently
    }];
}

- (void)customiseServersWithWellKnown:(MXWellKnown*)wellKnown
{
    if (self.customServersContainer.hidden)
    {
        // Check wellKnown data with application default servers
        // If different, use custom servers
        if (![self.defaultHomeServerUrl isEqualToString:wellKnown.homeServer.baseUrl]
            || ![self.defaultIdentityServerUrl isEqualToString:wellKnown.identityServer.baseUrl])
        {
            [self showCustomHomeserver:wellKnown.homeServer.baseUrl andIdentityServer:wellKnown.identityServer.baseUrl];
        }
    }
    else
    {
        if ([self.defaultHomeServerUrl isEqualToString:wellKnown.homeServer.baseUrl]
            && [self.defaultIdentityServerUrl isEqualToString:wellKnown.identityServer.baseUrl])
        {
            // wellKnown matches with application default servers
            // Hide custom servers
            [self hideCustomServers:YES];
        }
        else
        {
            NSString *customHomeServerURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"customHomeServerURL"];
            NSString *customIdentityServerURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"customIdentityServerURL"];

            if (![customHomeServerURL isEqualToString:wellKnown.homeServer.baseUrl]
                || ![customIdentityServerURL isEqualToString:wellKnown.identityServer.baseUrl])
            {
                // Update custom servers
                [self showCustomHomeserver:wellKnown.homeServer.baseUrl andIdentityServer:wellKnown.identityServer.baseUrl];
            }
        }
    }
}

- (void)showCustomHomeserver:(NSString*)homeserver andIdentityServer:(NSString*)identityServer
{
    // Store the wellknown data into NSUserDefaults before displaying them
    [[NSUserDefaults standardUserDefaults] setObject:homeserver forKey:@"customHomeServerURL"];

    if (identityServer)
    {
        [[NSUserDefaults standardUserDefaults] setObject:identityServer forKey:@"customIdentityServerURL"];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"customIdentityServerURL"];
    }

    // And show custom servers
    [self hideCustomServers:NO];
}

@end
