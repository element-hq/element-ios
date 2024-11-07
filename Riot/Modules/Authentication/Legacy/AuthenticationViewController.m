/*
Copyright 2019-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "AuthenticationViewController.h"

#import "MXSession+Riot.h"

#import "AuthInputsView.h"
#import "ForgotPasswordInputsView.h"
#import "AuthFallBackViewController.h"

#import "GeneratedInterface-Swift.h"

static const CGFloat kAuthInputContainerViewMinHeightConstraintConstant = 150.0;

@interface AuthenticationViewController () <AuthFallBackViewControllerDelegate, SetPinCoordinatorBridgePresenterDelegate,
    SocialLoginListViewDelegate,
    SSOAuthenticationPresenterDelegate
>
{
    /**
     The default country code used to initialize the mobile phone number input.
     */
    NSString *defaultCountryCode;
    
    /**
     Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
     */
    id kThemeServiceDidChangeThemeNotificationObserver;

    /**
     Observe AppDelegateUniversalLinkDidChangeNotification to handle universal link changes.
     */
    id universalLinkDidChangeNotificationObserver;

    /**
     Server discovery.
     */
    MXAutoDiscovery *autoDiscovery;

    AuthFallBackViewController *authFallBackViewController;
    
    // successful login credentials
    MXCredentials *loginCredentials;
    
    // Check false display of this screen only once
    BOOL didCheckFalseAuthScreenDisplay;
}

@property (nonatomic, readonly) BOOL isIdentityServerConfigured;
@property (nonatomic, strong) SetPinCoordinatorBridgePresenter *setPinCoordinatorBridgePresenter;
@property (nonatomic, strong) KeyboardAvoider *keyboardAvoider;

@property (weak, nonatomic) IBOutlet UIView *socialLoginContainerView;
@property (nonatomic, weak) SocialLoginListView *socialLoginListView;

@property (nonatomic, strong) SSOAuthenticationPresenter *ssoAuthenticationPresenter;

// Current SSO flow containing Identity Providers. Used for `socialLoginListView`
@property (nonatomic, strong) MXLoginSSOFlow *currentLoginSSOFlow;

// Current SSO transaction id used to identify and validate the SSO authentication callback
@property (nonatomic, strong) NSString *ssoCallbackTxnId;
/**
 The SSO provider that was used to successfully complete login, otherwise `nil`.
 */
@property (nonatomic, readwrite, nullable) SSOIdentityProvider *ssoIdentityProvider;

@property (nonatomic, getter = isFirstViewAppearing) BOOL firstViewAppearing;

@property (nonatomic, strong) MXKErrorAlertPresentation *errorPresenter;

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
    
    didCheckFalseAuthScreenDisplay = NO;
    
    _firstViewAppearing = YES;
    
    self.errorPresenter = [MXKErrorAlertPresentation new];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = nil;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:VectorL10n.authRegister
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(onButtonPressed:)];
    
    if (BuildSettings.forceHomeserverSelection)
    {
        self.defaultHomeServerUrl = nil;
    }
    else
    {
        self.defaultHomeServerUrl = RiotSettings.shared.homeserverUrlString;
    }
    
    self.defaultIdentityServerUrl = RiotSettings.shared.identityServerUrlString;
    
    self.welcomeImageView.image = AssetSharedImages.horizontalLogo.image;
    
    [self.submitButton.layer setCornerRadius:5];
    self.submitButton.clipsToBounds = YES;
    [self.submitButton setTitle:[VectorL10n authLogin] forState:UIControlStateNormal];
    [self.submitButton setTitle:[VectorL10n authLogin] forState:UIControlStateHighlighted];
    self.submitButton.enabled = YES;
    
    [self.skipButton.layer setCornerRadius:5];
    self.skipButton.clipsToBounds = YES;
    [self.skipButton setTitle:[VectorL10n authSkip] forState:UIControlStateNormal];
    [self.skipButton setTitle:[VectorL10n authSkip] forState:UIControlStateHighlighted];
    self.skipButton.enabled = YES;
    
    [self.customServersTickButton setImage:AssetImages.selectionUntick.image forState:UIControlStateNormal];
    [self.customServersTickButton setImage:AssetImages.selectionUntick.image forState:UIControlStateHighlighted];
    
    if (!BuildSettings.authScreenShowRegister)
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.title = nil;
    }
    self.serverOptionsContainer.hidden = !BuildSettings.authScreenShowCustomServerOptions;
    
    [self setCustomServerFieldsVisible:NO];

    // Soft logout section
    self.softLogoutClearDataButton.layer.cornerRadius = 5;
    self.softLogoutClearDataButton.clipsToBounds = YES;
    [self.softLogoutClearDataButton setTitle:[VectorL10n authSoftlogoutClearDataButton] forState:UIControlStateNormal];
    [self.softLogoutClearDataButton setTitle:[VectorL10n authSoftlogoutClearDataButton] forState:UIControlStateHighlighted];
    self.softLogoutClearDataButton.enabled = YES;
    self.softLogoutClearDataContainer.hidden = YES;
    
    // The view controller dismiss itself on successful login.
    self.delegate = self;
    
    self.homeServerTextField.placeholder = [VectorL10n authHomeServerPlaceholder];
    self.identityServerTextField.placeholder = [VectorL10n authIdentityServerPlaceholder];
    
    self.authenticationActivityIndicatorContainerView.layer.cornerRadius = 5;
    [self.authenticationActivityIndicator addObserver:self
                                           forKeyPath:@"hidden"
                                              options:0
                                              context:nil];
    
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
    universalLinkDidChangeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AppDelegateUniversalLinkDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        [self updateUniversalLink];
    }];

    [self userInterfaceThemeDidChange];
    [self updateUniversalLink];
    
    _keyboardAvoider = [[KeyboardAvoider alloc] initWithScrollViewContainerView:self.view scrollView:self.authenticationScrollView];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar
                          withModernScrollEdgeAppearance:YES];
    
    self.view.backgroundColor = ThemeService.shared.theme.backgroundColor;

    self.authenticationScrollView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    self.welcomeImageView.tintColor = ThemeService.shared.theme.tintColor;

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
    
    self.authenticationActivityIndicator.color = ThemeService.shared.theme.textSecondaryColor;
    self.authenticationActivityIndicatorContainerView.backgroundColor = ThemeService.shared.theme.baseColor;
    self.noFlowLabel.textColor = ThemeService.shared.theme.warningColor;
    
    NSMutableAttributedString *forgotPasswordTitle = [[NSMutableAttributedString alloc] initWithString:[VectorL10n authForgotPassword]];
    [forgotPasswordTitle addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, forgotPasswordTitle.length)];
    [forgotPasswordTitle addAttribute:NSForegroundColorAttributeName value:ThemeService.shared.theme.tintColor range:NSMakeRange(0, forgotPasswordTitle.length)];
    [self.forgotPasswordButton setAttributedTitle:forgotPasswordTitle forState:UIControlStateNormal];
    [self.forgotPasswordButton setAttributedTitle:forgotPasswordTitle forState:UIControlStateHighlighted];
    
    NSMutableAttributedString *forgotPasswordTitleDisabled = [[NSMutableAttributedString alloc] initWithAttributedString:forgotPasswordTitle];
    [forgotPasswordTitleDisabled addAttribute:NSForegroundColorAttributeName value:[ThemeService.shared.theme.tintColor colorWithAlphaComponent:0.3] range:NSMakeRange(0, forgotPasswordTitle.length)];
    [self.forgotPasswordButton setAttributedTitle:forgotPasswordTitleDisabled forState:UIControlStateDisabled];
    
    [self updateForgotPwdButtonVisibility];
    
    NSAttributedString *serverOptionsTitle = [[NSAttributedString alloc] initWithString:[VectorL10n authUseServerOptions] attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.textSecondaryColor, NSFontAttributeName: [UIFont systemFontOfSize:14]}];
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
    
    self.customServersTickButton.tintColor = ThemeService.shared.theme.tintColor;

    [self.authInputsView customizeViewRendering];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)updateUniversalLink
{
    UniversalLink *link = [AppDelegate theDelegate].lastHandledUniversalLink;
    if (link)
    {
        NSString *emailAddress = link.queryParams[@"email"];
        if (emailAddress && self.authInputsView)
        {
            AuthInputsView *inputsView = (AuthInputsView *)self.authInputsView;
            inputsView.emailTextField.text = emailAddress;
        }
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_keyboardAvoider startAvoiding];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.isFirstViewAppearing)
    {
        self.firstViewAppearing = NO;
    }

    // Verify that the app does not show the authentication screen whereas
    // the user has already logged in.
    // This bug rarely happens (https://github.com/vector-im/riot-ios/issues/1643)
    // but it invites the user to log in again. They will then lose all their
    // e2e messages.
    if (!didCheckFalseAuthScreenDisplay)
    {
        didCheckFalseAuthScreenDisplay = YES;
        
        MXLogDebug(@"[AuthenticationVC] viewDidAppear: Checking false logout");
        [MXKAccountManager sharedManagerWithReload: YES];
        if ([MXKAccountManager sharedManager].activeAccounts.count)
        {
            // For now, we do not have better solution than forcing the user to restart the app
            [NSException raise:@"False logout. Kill the app" format:@"AuthenticationViewController has been displayed whereas there is an existing account"];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [_keyboardAvoider stopAvoiding];
    
    [super viewDidDisappear:animated];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (self.isFirstViewAppearing)
    {
        [self refreshContentViewHeightConstraint];
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

    if (universalLinkDidChangeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:universalLinkDidChangeNotificationObserver];
        universalLinkDidChangeNotificationObserver = nil;
    }
    
    [self.authenticationActivityIndicator removeObserver:self forKeyPath:@"hidden"];

    autoDiscovery = nil;
    _keyboardAvoider = nil;
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

    if (authType == MXKAuthenticationTypeLogin)
    {
        [self.submitButton setTitle:[VectorL10n authLogin] forState:UIControlStateNormal];
        [self.submitButton setTitle:[VectorL10n authLogin] forState:UIControlStateHighlighted];
    }
    else if (authType == MXKAuthenticationTypeRegister)
    {
        [self.submitButton setTitle:[VectorL10n authRegister] forState:UIControlStateNormal];
        [self.submitButton setTitle:[VectorL10n authRegister] forState:UIControlStateHighlighted];
    }
    else if (authType == MXKAuthenticationTypeForgotPassword)
    {
        if (isPasswordReseted)
        {
            [self.submitButton setTitle:[VectorL10n authReturnToLogin] forState:UIControlStateNormal];
            [self.submitButton setTitle:[VectorL10n authReturnToLogin] forState:UIControlStateHighlighted];
        }
        else
        {
            [self.submitButton setTitle:[VectorL10n authSendResetEmail] forState:UIControlStateNormal];
            [self.submitButton setTitle:[VectorL10n authSendResetEmail] forState:UIControlStateHighlighted];
        }
    }
    
    [self updateAuthInputViewVisibility];
    [self updateForgotPwdButtonVisibility];
    [self updateSoftLogoutClearDataContainerVisibility];
    [self updateSocialLoginViewVisibility];
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
    
    // the authentication indicator should be the front most view
    [self.authInputsContainerView bringSubviewToFront:self.authenticationActivityIndicatorContainerView];
}

- (void)updateAuthInputViewVisibility
{
    BOOL hideAuthInputView = NO;
    
    // Hide input view when there is only social login actions to present at login
    if ((self.authType == MXKAuthenticationTypeLogin)
        && self.currentLoginSSOFlow
        && !self.isAuthSessionContainsPasswordFlow
        && BuildSettings.authScreenShowSocialLoginSection)
    {
        hideAuthInputView = YES;
    }
    
    // Note: Registration will hide the input view in onFailureDuringMXOperation
    // if registration has been disabled.
    
    self.authInputsView.hidden = hideAuthInputView;
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled
{
    super.userInteractionEnabled = userInteractionEnabled;

    // Reset
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
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
        self.navigationItem.rightBarButtonItem.title = [VectorL10n cancel];

        // Remove the potential back button.
        self.navigationItem.leftBarButtonItem = nil;
        [self.navigationItem setHidesBackButton:YES];
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
            if (!authInputsview.isSingleSignOnRequired
                && !self.softLogoutCredentials
                && BuildSettings.authScreenShowRegister)
            {
                self.navigationItem.rightBarButtonItem.title = [VectorL10n authRegister];
            }
            else
            {
                // Disable register on SSO
                self.navigationItem.rightBarButtonItem.enabled = NO;
                self.navigationItem.rightBarButtonItem.title = nil;
            }
        }
        else if (self.authType == MXKAuthenticationTypeRegister)
        {
            self.navigationItem.rightBarButtonItem.title = [VectorL10n authLogin];
            
            // Restore the back button
            if (authInputsview)
            {
                [self updateRegistrationScreenWithThirdPartyIdentifiersHidden:authInputsview.thirdPartyIdentifiersHidden];
            }
        }
        else if (self.authType == MXKAuthenticationTypeForgotPassword)
        {
            // The right bar button is used to return to login.
            self.navigationItem.rightBarButtonItem.title = [VectorL10n cancel];
        }
    }
}

- (BOOL)continueSSOLoginWithToken:(NSString*)loginToken txnId:(NSString*)txnId
{
    // The presenter isn't dismissed automatically when finishing via a deep link
    if (self.ssoAuthenticationPresenter)
    {
        [self dismissSSOAuthenticationPresenter];
    }
    
    // Check if transaction id is the same as expected
    if (loginToken &&
        txnId && self.ssoCallbackTxnId
        && [txnId isEqualToString:self.ssoCallbackTxnId])
    {
        [self loginWithToken:loginToken];
        return YES;
    }
    
    MXLogDebug(@"[AuthenticationVC] Fail to continue SSO login");
    return NO;
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

    UINavigationController *navigationController = [[RiotNavigationController alloc] initWithRootViewController:authFallBackViewController];
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
    
    if (softLogoutCredentials)
    {
        // Customise the screen for soft logout
        self.customServersTickButton.hidden = YES;
        self.navigationItem.rightBarButtonItem.title = nil;
        self.navigationItem.title = [VectorL10n authSoftlogoutSignedOut];
        [self showSoftLogoutClearDataContainer];
    }
    else
    {
        // Customise the screen for regular authentication.
        self.customServersTickButton.hidden = NO;
        [self updateRightBarButtonItem];
        self.navigationItem.title = nil;
        self.softLogoutClearDataContainer.hidden = YES;
    }
}

- (void)showSoftLogoutClearDataContainer
{
    NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:[VectorL10n authSoftlogoutClearData]
                                                                                attributes:@{
                                                                                             NSFontAttributeName: [UIFont boldSystemFontOfSize:14]
                                                                                             }];
    
    [message appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n"]];
    
    NSString *string = [NSString stringWithFormat:@"%@\n\n%@",
                        [VectorL10n authSoftlogoutClearDataMessage1],
                        [VectorL10n authSoftlogoutClearDataMessage2]];
    
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

/**
 Filter and prioritise flows supported by the app.

 @param authSession the auth session coming from the HS.
 @return a new auth session
 */
- (MXAuthenticationSession*)handleSupportedFlowsInAuthenticationSession:(MXAuthenticationSession *)authSession
{
    MXLoginSSOFlow *ssoFlow;
    MXLoginFlow *passwordFlow;
    NSMutableArray *supportedFlows = [NSMutableArray array];

    for (MXLoginFlow *flow in authSession.flows)
    {
        // Remove known flows we do not support
        if (![flow.type isEqualToString:kMXLoginFlowTypeToken])
        {
            MXLogDebug(@"[AuthenticationVC] handleSupportedFlowsInAuthenticationSession: Filter out flow %@", flow.type);
            [supportedFlows addObject:flow];
        }

        if ([flow.type isEqualToString:kMXLoginFlowTypePassword])
        {
            passwordFlow = flow;
        }

        if ([flow isKindOfClass:MXLoginSSOFlow.class])
        {
            MXLogDebug(@"[AuthenticationVC] handleSupportedFlowsInAuthenticationSession: Prioritise flow %@", flow.type);
            ssoFlow = (MXLoginSSOFlow *)flow;
        }
    }

    // Prioritise SSO over other flows
    if (ssoFlow)
    {
        [supportedFlows removeAllObjects];
        [supportedFlows addObject:ssoFlow];

        // If the SSO contains Identity Providers list and password
        // Display both social login and password input
        if (ssoFlow.identityProviders.count && passwordFlow)
        {
            [supportedFlows addObject:passwordFlow];
        }
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

- (void)refreshAuthenticationSession
{
    // Hide the social login buttons while the session refreshes
    [self hideSocialLoginView];
    [super refreshAuthenticationSession];
}

- (void)handleAuthenticationSession:(MXAuthenticationSession *)authSession withFallbackSSOFlow:(MXLoginSSOFlow *)fallbackSSOFlow
{
    // Make some cleaning from the server response according to what the app supports
    authSession = [self handleSupportedFlowsInAuthenticationSession:authSession];
    
    [super handleAuthenticationSession:authSession withFallbackSSOFlow:fallbackSSOFlow];
    
    self.currentLoginSSOFlow = [self loginSSOFlowWithProvidersFromFlows:authSession.flows] ?: fallbackSSOFlow;
    
    [self updateAuthInputViewVisibility];
    [self updateSocialLoginViewVisibility];
        
    AuthInputsView *authInputsview;
    if ([self.authInputsView isKindOfClass:AuthInputsView.class])
    {
        authInputsview = (AuthInputsView*)self.authInputsView;
        [self updateUniversalLink];
    }

    // Hide "Forgot password" and "Log in" buttons in case of SSO
    [self updateForgotPwdButtonVisibility];
    [self updateSoftLogoutClearDataContainerVisibility];

    self.submitButton.hidden = authInputsview.isSingleSignOnRequired || authInputsview.isHidden;

    // Bind ssoButton again if self.authInputsView has changed
    [authInputsview.ssoButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    if (authInputsview.isSingleSignOnRequired && self.softLogoutCredentials)
    {
        // Remove submitButton so that the 2nd contraint on softLogoutClearDataContainer.top will be applied
        // That makes softLogoutClearDataContainer appear upper in the screen
        [self.submitButton removeFromSuperview];
    }
    
    [self refreshContentViewHeightConstraint];
}

- (BOOL)isAuthSessionContainsPasswordFlow
{
    BOOL containsPassword = NO;
    
    if (self.authInputsView.authSession)
    {
        containsPassword = [self containsPasswordFlowInFlows:self.authInputsView.authSession.flows];
    }
    
    return containsPassword;
}

- (BOOL)containsPasswordFlowInFlows:(NSArray<MXLoginFlow*>*)loginFlows
{
    for (MXLoginFlow *loginFlow in loginFlows)
    {
        if ([loginFlow.type isEqualToString:kMXLoginFlowTypePassword])
        {
            return YES;
        }
    }
    
    return NO;
}

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == self.customServersTickButton)
    {
        [self setCustomServerFieldsVisible:self.customServersContainer.hidden];
    }
    else if (sender == self.forgotPasswordButton)
    {
        if (!self.isIdentityServerConfigured)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:[VectorL10n error]
                                                                           message:[VectorL10n authForgotPasswordErrorNoConfiguredIdentityServer]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok] style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            
            return;
        }
        else
        {
            // Update UI to reset password
            self.authType = MXKAuthenticationTypeForgotPassword;
        }
    }
    else if (sender == self.navigationItem.rightBarButtonItem)
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
            [self updateRightBarButtonItem];
        }
        else
        {
            self.authType = MXKAuthenticationTypeLogin;
            [self updateRightBarButtonItem];
        }
    }
    else if (sender == self.navigationItem.leftBarButtonItem)
    {
        if ([self.authInputsView isKindOfClass:AuthInputsView.class])
        {
            AuthInputsView *authInputsview = (AuthInputsView*)self.authInputsView;
            
            // Hide the supported 3rd party ids which may be added to the account
            authInputsview.thirdPartyIdentifiersHidden = YES;
            
            [self updateRegistrationScreenWithThirdPartyIdentifiersHidden:YES];
            
            // Show the social login buttons again if needed.
            [self updateSocialLoginViewVisibility];
            
            // Allow backward navigation in the flow again.
            [self.navigationItem setHidesBackButton:NO];
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
                                MXLogDebug(@"[AuthenticationVC] User name is already use");
                                [self onFailureDuringAuthRequest:[NSError errorWithDomain:MXKAuthErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:[VectorL10n authUsernameInUse]}]];
                            }
                            //   - the server quota limits is not reached
                            else if ([mxError.errcode isEqualToString:kMXErrCodeStringResourceLimitExceeded])
                            {
                                [self showResourceLimitExceededError:mxError.userInfo];
                            }
                            else
                            {
                                [self.authenticationActivityIndicator stopAnimating];
                                
                                // Hide the social login buttons now that a different flow has started.
                                [self hideSocialLoginView];
                                
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
        [self presentDefaultSSOAuthentication];
    }
    else if (sender == self.softLogoutClearDataButton)
    {
        [self.authVCDelegate authenticationViewControllerDidRequestClearAllData:self];
    }
    else
    {
        [super onButtonPressed:sender];
    }

    [self updateSoftLogoutClearDataContainerVisibility];
}

- (void)onFailureDuringAuthRequest:(NSError *)error
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

- (void)onSuccessfulLogin:(MXCredentials*)credentials
{
    //  Is pin protection forced?
    if ([PinCodePreferences shared].forcePinProtection)
    {
        loginCredentials = credentials;
        
        SetPinCoordinatorViewMode viewMode = SetPinCoordinatorViewModeSetPin;
        switch (self.authType) {
            case MXKAuthenticationTypeLogin:
                viewMode = SetPinCoordinatorViewModeSetPinAfterLogin;
                break;
            case MXKAuthenticationTypeRegister:
                viewMode = SetPinCoordinatorViewModeSetPinAfterRegister;
                break;
            default:
                break;
        }
        
        SetPinCoordinatorBridgePresenter *presenter = [[SetPinCoordinatorBridgePresenter alloc] initWithSession:nil viewMode:viewMode];
        presenter.delegate = self;
        [presenter presentFrom:self animated:YES];
        self.setPinCoordinatorBridgePresenter = presenter;
        return;
    }
    
    [self afterSetPinFlowCompletedWithCredentials:credentials];
}

- (void)updateRightBarButtonItem
{
    if (self.authType == MXKAuthenticationTypeLogin)
    {
        self.navigationItem.rightBarButtonItem.title = [VectorL10n authRegister];
    }
    else
    {
        self.navigationItem.rightBarButtonItem.title = [VectorL10n authLogin];
    }
}

- (void)updateForgotPwdButtonVisibility
{
    AuthInputsView *authInputsview;
    if ([self.authInputsView isKindOfClass:AuthInputsView.class])
    {
        authInputsview = (AuthInputsView*)self.authInputsView;
    }
    
    BOOL showForgotPasswordButton = NO;

    if (BuildSettings.authScreenShowForgotPassword && authInputsview.isHidden == NO)
    {
        showForgotPasswordButton = (self.authType == MXKAuthenticationTypeLogin) && !authInputsview.isSingleSignOnRequired;
    }
    
    self.forgotPasswordButton.hidden = !showForgotPasswordButton;
}

- (void)afterSetPinFlowCompletedWithCredentials:(MXCredentials*)credentials
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
            
            alert = [UIAlertController alertControllerWithTitle:[VectorL10n warning] message:[VectorL10n authAddEmailAndPhoneWarning] preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
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

#pragma mark -

- (void)updateRegistrationScreenWithThirdPartyIdentifiersHidden:(BOOL)thirdPartyIdentifiersHidden
{
    self.skipButton.hidden = thirdPartyIdentifiersHidden;
    
    // Do not display the skip button if the 3PID is mandatory
    if (!thirdPartyIdentifiersHidden)
    {
        if ([self.authInputsView isKindOfClass:AuthInputsView.class])
        {
            AuthInputsView *authInputsview = (AuthInputsView*)self.authInputsView;
            if (authInputsview.isThirdPartyIdentifierRequired)
            {
                self.skipButton.hidden = YES;
            }
        }
    }
    
    self.serverOptionsContainer.hidden = !thirdPartyIdentifiersHidden
                                            || !BuildSettings.authScreenShowCustomServerOptions;
    [self refreshContentViewHeightConstraint];
    
    if (thirdPartyIdentifiersHidden)
    {
        [self.submitButton setTitle:[VectorL10n authRegister] forState:UIControlStateNormal];
        [self.submitButton setTitle:[VectorL10n authRegister] forState:UIControlStateHighlighted];
        
        self.navigationItem.leftBarButtonItem = nil;
    }
    else
    {
        [self.submitButton setTitle:[VectorL10n authSubmit] forState:UIControlStateNormal];
        [self.submitButton setTitle:[VectorL10n authSubmit] forState:UIControlStateHighlighted];
        
        UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:VectorL10n.back
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(onButtonPressed:)];
        self.navigationItem.leftBarButtonItem = leftBarButtonItem;
    }
}

- (void)refreshContentViewHeightConstraint
{
    [self.view layoutIfNeeded];
    
    // Refresh content view height by considering the options container display.
    CGFloat constant = self.optionsContainer.frame.origin.y + 10;
    
    if (self.authInputsView.isHidden == NO)
    {
        self.authInputContainerViewMinHeightConstraint.constant = kAuthInputContainerViewMinHeightConstraintConstant;
        self.authInputContainerViewHeightConstraint.constant = self.authInputsView.viewHeightConstraint.constant;
    }
    else
    {
        self.authInputContainerViewMinHeightConstraint.constant = 0;
        self.authInputContainerViewHeightConstraint.constant = 0;
    }
        
    // FIX: When authInputsView present recaptcha the height is not taken into account, add it manually here.
    AuthInputsView *authInputsview;
    if ([self.authInputsView isKindOfClass:AuthInputsView.class])
    {
        authInputsview = (AuthInputsView*)self.authInputsView;
        
        if (!authInputsview.recaptchaContainer.hidden)
        {
            constant+=authInputsview.frame.size.height;
        }
    }
    
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
            else
            {
                constant += self.customServersTickButton.frame.size.height;
            }
        }
    }

    if (!self.softLogoutClearDataContainer.isHidden)
    {
        // The soft logout clear data section adds more height
        constant += self.softLogoutClearDataContainer.frame.size.height;
    }
    
    if (self.isSocialLoginViewShown)
    {
        constant += [self socialLoginViewHeightFittingWidth:self.contentView.frame.size.width];
    }

    self.contentViewHeightConstraint.constant = constant;
    
    [self.view layoutIfNeeded];
}

- (void)setCustomServerFieldsVisible:(BOOL)isVisible
{
    if (self.customServersContainer.isHidden != isVisible)
    {
        return;
    }
    
    if (!isVisible)
    {
        [self.homeServerTextField resignFirstResponder];
        [self.identityServerTextField resignFirstResponder];
        
        // Report server url typed by the user as custom url.
        [self saveCustomServerInputs];
                
        // Restore default configuration
        if (BuildSettings.forceHomeserverSelection)
        {
            [self setHomeServerTextFieldText:nil];
        }
        else
        {
            [self setHomeServerTextFieldText:self.defaultHomeServerUrl];
        }
        [self setIdentityServerTextFieldText:self.defaultIdentityServerUrl];
        
        [self.customServersTickButton setImage:AssetImages.selectionUntick.image forState:UIControlStateNormal];
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
        
        [self.customServersTickButton setImage:AssetImages.selectionTick.image forState:UIControlStateNormal];
        self.customServersContainer.hidden = NO;
        
        // Refresh content view height
        [self refreshContentViewHeightConstraint];

        // Scroll to display server options
        CGPoint offset = self.authenticationScrollView.contentOffset;
        offset.y += self.customServersContainer.frame.size.height;
        self.authenticationScrollView.contentOffset = offset;
    }
}

- (void)saveCustomServerInputs
{
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
}

- (void)showResourceLimitExceededError:(NSDictionary *)errorDict
{
    MXLogDebug(@"[AuthenticationVC] showResourceLimitExceededError");

    [self showResourceLimitExceededError:errorDict onAdminContactTapped:^(NSURL *adminContactURL) {

        [[UIApplication sharedApplication] vc_open:adminContactURL completionHandler:^(BOOL success) {
           if (!success)
           {
               MXLogDebug(@"[AuthenticationVC] adminContact(%@) cannot be opened", adminContactURL);
           }
        }];
    }];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.authenticationScrollView vc_scrollTo:textField with:UIEdgeInsetsMake(-20, 0, -20, 0) animated:YES];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // Override here the handling of the authInputsView height change.
    if ([@"viewHeightConstraint.constant" isEqualToString:keyPath])
    {
        // Refresh content view height by considering the updated frame of the options container.
        [self refreshContentViewHeightConstraint];
    }
    else if ([@"hidden" isEqualToString:keyPath])
    {
        UIActivityIndicatorView *indicator = (UIActivityIndicatorView*)object;
        [self.authenticationActivityIndicatorContainerView setHidden:indicator.hidden];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - MXKAuthenticationViewControllerDelegate

- (void)authenticationViewController:(MXKAuthenticationViewController *)authenticationViewController didLogWithUserId:(NSString *)userId
{
    self.userInteractionEnabled = NO;
    [self.authenticationActivityIndicator startAnimating];
    
    // Save customized server inputs if used
    if (!self.customServersContainer.isHidden)
    {
        [self saveCustomServerInputs];
    }
    
    MXKAccount *account = [[MXKAccountManager sharedManager] accountForUserId:userId];
    MXSession *session = account.mxSession;
    
    BOOL botCreationEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"enableBotCreation"];
    
    // Create DM with Riot-bot on new account creation.
    if (self.authType == MXKAuthenticationTypeRegister && botCreationEnabled)
    {
        MXRoomCreationParameters *roomCreationParameters = [MXRoomCreationParameters parametersForDirectRoomWithUser:@"@riot-bot:matrix.org"];
        [session createRoomWithParameters:roomCreationParameters success:nil failure:^(NSError *error) {
            MXLogDebug(@"[AuthenticationVC] Create chat with riot-bot failed");
        }];
    }
    
    // Ask the coordinator to show the loading spinner whilst waiting.
    [self.authVCDelegate authenticationViewController:self
                                  didLoginWithSession:session
                                          andPassword:self.authInputsView.password
                                orSSOIdentityProvider:self.ssoIdentityProvider];
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

                self->alert = [UIAlertController alertControllerWithTitle:[VectorL10n authAutodiscoverInvalidResponse]
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleAlert];

                [self->alert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
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
            [self setCustomServerFieldsVisible:NO];
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
    [self setCustomServerFieldsVisible:YES];
}

#pragma mark - SetPinCoordinatorBridgePresenterDelegate

- (void)setPinCoordinatorBridgePresenterDelegateDidComplete:(SetPinCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.setPinCoordinatorBridgePresenter = nil;

    [self afterSetPinFlowCompletedWithCredentials:loginCredentials];
}

- (void)setPinCoordinatorBridgePresenterDelegateDidCancel:(SetPinCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    //  enable the view again
    [self setUserInteractionEnabled:YES];
    
    //  stop the spinner
    [self.authenticationActivityIndicator stopAnimating];
    
    //  then, just close the enter pin screen
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.setPinCoordinatorBridgePresenter = nil;
}

#pragma mark - Social login view management

- (BOOL)isSocialLoginViewShown
{
    return self.socialLoginListView.superview
    && !self.socialLoginListView.isHidden
    && self.currentLoginSSOFlow.identityProviders.count;
}

- (CGFloat)socialLoginViewHeightFittingWidth:(CGFloat)width
{
    NSArray<MXLoginSSOIdentityProvider*> *identityProviders =  self.currentLoginSSOFlow.identityProviders;
    
    if (!identityProviders.count && self.socialLoginListView)
    {
        return 0.0;
    }
    
    return [SocialLoginListView contentViewHeightWithIdentityProviders:identityProviders mode:self.socialLoginListView.mode fitting:self.contentView.frame.size.width];
}

- (void)showSocialLoginViewWithLoginSSOFlow:(MXLoginSSOFlow*)loginSSOFlow andMode:(SocialLoginButtonMode)mode
{
    SocialLoginListView *listView = self.socialLoginListView;
    
    if (!listView)
    {
        listView = [SocialLoginListView instantiate];
        [self.socialLoginContainerView vc_addSubViewMatchingParent:listView];
        self.socialLoginListView = listView;
        listView.delegate = self;
    }
    
    [listView updateWith:loginSSOFlow.identityProviders mode:mode];
    
    [self refreshContentViewHeightConstraint];
}

- (void)hideSocialLoginView
{
    [self.socialLoginListView removeFromSuperview];
    [self refreshContentViewHeightConstraint];
}

- (void)updateSocialLoginViewVisibility
{
    SocialLoginButtonMode socialLoginButtonMode = SocialLoginButtonModeContinue;

    BOOL showSocialLoginView = BuildSettings.authScreenShowSocialLoginSection && (self.currentLoginSSOFlow ? YES : NO);
    
    switch (self.authType)
    {
        case MXKAuthenticationTypeForgotPassword:
            showSocialLoginView = NO;
            break;
        case MXKAuthenticationTypeRegister:
            socialLoginButtonMode = SocialLoginButtonModeSignUp;
            break;
        case MXKAuthenticationTypeLogin:
            if (((AuthInputsView*)self.authInputsView).isSingleSignOnRequired)
            {
                socialLoginButtonMode = SocialLoginButtonModeContinue;
            }
            else
            {
                socialLoginButtonMode = SocialLoginButtonModeSignIn;
            }
            break;
        default:
            break;
    }
    
    if (showSocialLoginView)
    {
        [self showSocialLoginViewWithLoginSSOFlow:self.currentLoginSSOFlow andMode:socialLoginButtonMode];
    }
    else
    {
        [self hideSocialLoginView];
    }
}

#pragma mark - SocialLoginListViewDelegate

- (void)socialLoginListView:(SocialLoginListView *)socialLoginListView didTapSocialButtonWithProvider:(SSOIdentityProvider *)identityProvider
{
    [self presentSSOAuthenticationForIdentityProvider:identityProvider];
}

#pragma mark - SSOIdentityProviderAuthenticationPresenter

- (void)presentSSOAuthenticationForIdentityProvider:(SSOIdentityProvider*)identityProvider
{
    NSString *homeServerStringURL = self.homeServerTextField.text;
    
    if (!homeServerStringURL)
    {
        return;
    }
    
    SSOAuthenticationService *ssoAuthenticationService = [[SSOAuthenticationService alloc] initWithHomeserverStringURL:homeServerStringURL];
    
    SSOAuthenticationPresenter *presenter = [[SSOAuthenticationPresenter alloc] initWithSsoAuthenticationService:ssoAuthenticationService];
    
    presenter.delegate = self;
    
    // Generate a unique identifier that will identify the success callback URL
    NSString *transactionId = [MXTools generateTransactionId];
    
    [presenter presentForIdentityProvider:identityProvider with: transactionId from:self animated:YES];
    
    self.ssoCallbackTxnId = transactionId;
    self.ssoAuthenticationPresenter = presenter;
}

- (void)presentDefaultSSOAuthentication
{
    [self presentSSOAuthenticationForIdentityProvider:nil];
}

- (void)dismissSSOAuthenticationPresenter
{
    [self.ssoAuthenticationPresenter dismissWithAnimated:YES completion:nil];
    self.ssoAuthenticationPresenter = nil;
}

// TODO: Move to SDK
- (void)loginWithToken:(NSString*)loginToken
{
    NSDictionary *parameters = @{
        @"type" : kMXLoginFlowTypeToken,
        @"token": loginToken
    };
    
    [self loginWithParameters:parameters];
}

#pragma mark - SSOAuthenticationPresenterDelegate

- (void)ssoAuthenticationPresenterDidCancel:(SSOAuthenticationPresenter *)presenter
{
    [self dismissSSOAuthenticationPresenter];
}

- (void)ssoAuthenticationPresenter:(SSOAuthenticationPresenter *)presenter authenticationDidFailWithError:(NSError *)error
{
    [self dismissSSOAuthenticationPresenter];
    [self.errorPresenter presentErrorFromViewController:self forError:error animated:YES handler:nil];
}

- (void)ssoAuthenticationPresenter:(SSOAuthenticationPresenter *)presenter
  authenticationSucceededWithToken:(NSString *)token
             usingIdentityProvider:(SSOIdentityProvider * _Nullable)identityProvider
{
    self.ssoIdentityProvider = identityProvider;
    [self dismissSSOAuthenticationPresenter];
    [self loginWithToken:token];
}

@end
