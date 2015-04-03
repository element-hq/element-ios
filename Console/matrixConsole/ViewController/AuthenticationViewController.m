/*
 Copyright 2014 OpenMarket Ltd
 
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

#import "MatrixSDKHandler.h"
#import "AppDelegate.h"
#import "MXCRegistrationWebView.h"

@interface AuthenticationViewController () {
    // Current request in progress
    MXHTTPOperation *mxCurrentOperation;
    
    // Array of flows supported by the home server and implemented by the app (for the current auth type)
    NSMutableArray *supportedFlows;
    
    // The current view in which auth inputs are displayed
    AuthInputsView *currentAuthInputsView;
    
    // reference to any opened alert view
    MXKAlert *alert;
}

// Return true if the provided flow (kMXLoginFlowType) is supported by the application
+ (BOOL)isImplementedFlowType:(NSString*)flowType forAuthType:(AuthenticationType)authType;

// The current authentication type
@property (nonatomic) AuthenticationType authType;
@property (nonatomic) MXLoginFlow *selectedFlow;

@property (strong, nonatomic) IBOutlet UIScrollView *authenticationScrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UILabel *createAccountLabel;

@property (weak, nonatomic) IBOutlet UIView *authInputsContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *authInputContainerViewHeightConstraint;
@property (weak, nonatomic) IBOutlet AuthInputsPasswordBasedView *authInputsPasswordBasedView;
@property (weak, nonatomic) IBOutlet AuthInputsEmailCodeBasedView *authInputsEmailCodeBasedView;

@property (weak, nonatomic) IBOutlet UITextField *homeServerTextField;
@property (weak, nonatomic) IBOutlet UILabel *homeServerInfoLabel;
@property (weak, nonatomic) IBOutlet UITextField *identityServerTextField;
@property (weak, nonatomic) IBOutlet UILabel *identityServerInfoLabel;

@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UIButton *authSwitchButton;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *noFlowLabel;
@property (weak, nonatomic) IBOutlet UIButton *retryButton;

@property (weak, nonatomic) IBOutlet UIView *registrationFallbackContentView;
@property (weak, nonatomic) IBOutlet MXCRegistrationWebView *registrationFallbackWebView;
@property (weak, nonatomic) IBOutlet UIButton *cancelRegistrationFallbackButton;

@end

@implementation AuthenticationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Force contentView in full width
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:0
                                                                         toItem:self.view
                                                                      attribute:NSLayoutAttributeLeft
                                                                     multiplier:1.0
                                                                       constant:0];
    [self.view addConstraint:leftConstraint];
    
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:0
                                                                          toItem:self.view
                                                                       attribute:NSLayoutAttributeRight
                                                                      multiplier:1.0
                                                                        constant:0];
    [self.view addConstraint:rightConstraint];
    
    _authenticationScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    _submitButton.enabled = NO;
    _authSwitchButton.enabled = YES;
    _authInputsPasswordBasedView.delegate = self;
    _authInputsEmailCodeBasedView.delegate = self;
    
    supportedFlows = [NSMutableArray array];
    
    _homeServerTextField.text = [[MatrixSDKHandler sharedHandler] homeServerURL];
    _identityServerTextField.text = [[MatrixSDKHandler sharedHandler] identityServerURL];
    
    // Set initial auth type
    _authType = AuthenticationTypeLogin;
}

- (void)dealloc {
    supportedFlows = nil;
    if (mxCurrentOperation){
        [mxCurrentOperation cancel];
        mxCurrentOperation = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Update supported authentication flow
    self.authType = _authType;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTextFieldChange:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self dismissKeyboard];

    // close any opened alert
    if (alert) {
        [alert dismiss:NO];
        alert = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingReachabilityDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
}

#pragma mark -

+ (BOOL)isImplementedFlowType:(NSString*)flowType forAuthType:(AuthenticationType)authType {
    if (authType == AuthenticationTypeLogin) {
        if ([flowType isEqualToString:kMXLoginFlowTypePassword]
            /*|| [flowType isEqualToString:kMXLoginFlowTypeEmailCode]*/) {
            return YES;
        }
    } else { // AuthenticationTypeRegister
        // No registration flow is supported yet
    }
    
    return NO;
}

- (void)setAuthType:(AuthenticationType)authType {
    if (authType == AuthenticationTypeLogin) {
        _createAccountLabel.hidden = YES;
        [_submitButton setTitle:@"Login" forState:UIControlStateNormal];
        [_submitButton setTitle:@"Login" forState:UIControlStateHighlighted];
        [_authSwitchButton setTitle:@"Create account" forState:UIControlStateNormal];
        [_authSwitchButton setTitle:@"Create account" forState:UIControlStateHighlighted];
    } else {
        _createAccountLabel.hidden = NO;
        [_submitButton setTitle:@"Sign up" forState:UIControlStateNormal];
        [_submitButton setTitle:@"Sign up" forState:UIControlStateHighlighted];
        [_authSwitchButton setTitle:@"Back" forState:UIControlStateNormal];
        [_authSwitchButton setTitle:@"Back" forState:UIControlStateHighlighted];
    }
    
    _authType = authType;
    
    // Update supported authentication flow
    [self refreshSupportedAuthFlow];
}

- (void)setSelectedFlow:(MXLoginFlow *)selectedFlow {
    // Hide views which depend on auth flow
    _submitButton.hidden = YES;
    _authInputsPasswordBasedView.hidden = YES;
    _authInputsEmailCodeBasedView.hidden = YES;
    _noFlowLabel.hidden = YES;
    _retryButton.hidden = YES;
    currentAuthInputsView = nil;
    
    // Select the right auth inputs view
    if ([selectedFlow.type isEqualToString:kMXLoginFlowTypePassword]) {
        currentAuthInputsView = _authInputsPasswordBasedView;
    } else if ([selectedFlow.type isEqualToString:kMXLoginFlowTypeEmailCode]) {
        currentAuthInputsView = _authInputsEmailCodeBasedView;
    }
    
    if (currentAuthInputsView) {
        _submitButton.hidden = NO;
        currentAuthInputsView.hidden = NO;
        currentAuthInputsView.authType = _authType;
        _authInputContainerViewHeightConstraint.constant = currentAuthInputsView.actualHeight;
    } else {
        // No input fields are displayed
        _authInputContainerViewHeightConstraint.constant = 80;
    }
    
    [self.view layoutIfNeeded];
    
    // Refresh content view height
    _contentViewHeightConstraint.constant = _authSwitchButton.frame.origin.y + _authSwitchButton.frame.size.height + 15;
    
    _selectedFlow = selectedFlow;
}

- (void)setUserInteractionEnabled:(BOOL)isEnabled {
    _submitButton.enabled = (isEnabled && currentAuthInputsView.areAllRequiredFieldsFilled && _homeServerTextField.text.length);
    _authSwitchButton.enabled = isEnabled;
    
    _homeServerTextField.enabled = isEnabled;
    _identityServerTextField.enabled = isEnabled;
}

- (void)refreshSupportedAuthFlow {
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    
    // Remove reachability observer
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingReachabilityDidChangeNotification object:nil];
    
    // Cancel potential request in progress
    [mxCurrentOperation cancel];
    mxCurrentOperation = nil;
    
    [_activityIndicator startAnimating];
    self.selectedFlow = nil;
    if (_authType == AuthenticationTypeLogin) {
        mxCurrentOperation = [mxHandler.mxRestClient getLoginFlow:^(NSArray *flows) {
            [self handleHomeServerFlows:flows];
        } failure:^(NSError *error) {
            NSLog(@"[AuthenticationVC] Failed to get Login flows: %@", error);
            [self onFailureDuringMXOperation:error];
        }];
    } else {
//        mxCurrentOperation = [mxHandler.mxRestClient getRegisterFlow:^(NSArray *flows) {
//            [self handleHomeServerFlows:flows];
//        } failure:^(NSError *error) {
//            NSLog(@"[AuthenticationVC] Failed to get Register flows: %@", error);
//            [self onFailureDuringMXOperation:error];
//        }];
        
        // Currently no registration flow are supported, we switch directly to the fallback page
        [self showRegistrationFallBackView:[mxHandler.mxRestClient registerFallback]];
    }
}

- (void)handleHomeServerFlows:(NSArray *)flows {
    [_activityIndicator stopAnimating];
    
    [supportedFlows removeAllObjects];
    for (MXLoginFlow* flow in flows) {
        if ([AuthenticationViewController isImplementedFlowType:flow.type forAuthType:_authType]) {
            // Check here all stages
            BOOL isSupported = YES;
            if (flow.stages.count) {
                for (NSString *stage in flow.stages) {
                    if ([AuthenticationViewController isImplementedFlowType:stage forAuthType:_authType] == NO) {
                        isSupported = NO;
                        break;
                    }
                }
            }
            
            if (isSupported) {
                [supportedFlows addObject:flow];
            }
        }
    }
    
    if (supportedFlows.count) {
        // FIXME display supported flows
        // Currently we select the first one
        self.selectedFlow = [supportedFlows firstObject];
    }
    
    if (!_selectedFlow) {
        // Notify user that no flow is supported
        if (_authType == AuthenticationTypeLogin) {
            _noFlowLabel.text = @"Currently we do not support Login flows defined by this Home Server.";
        } else {
            _noFlowLabel.text = @"Registration is not currently supported.";
        }
        NSLog(@"[AuthenticationVC] Warning: %@", _noFlowLabel.text);
        
        _noFlowLabel.hidden = NO;
        _retryButton.hidden = NO;
    }
}

- (void)onFailureDuringMXOperation:(NSError*)error {
    mxCurrentOperation = nil;
    
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == kCFURLErrorCancelled) {
        // Ignore this error
        return;
    }
    
    [_activityIndicator stopAnimating];
    
    // Alert user
    NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
    if (!title)
    {
        title = @"Error";
    }
    NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    
    alert = [[MXKAlert alloc] initWithTitle:title message:msg style:MXKAlertStyleAlert];
    alert.cancelButtonIndex = [alert addActionWithTitle:@"Dismiss" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {}];
    [alert showInViewController:self];
    
    // Display failure reason
    _noFlowLabel.hidden = NO;
    _noFlowLabel.text = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    if (!_noFlowLabel.text.length) {
        _noFlowLabel.text = @"We failed to retrieve authentication information from this Home Server";
    }
    _retryButton.hidden = NO;
    
    // Handle specific error code here
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        // Check network reachability
        if (error.code == NSURLErrorNotConnectedToInternet) {
            // Add reachability observer in order to launch a new request when network will be available
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReachabilityStatusChange:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
        } else if (error.code == kCFURLErrorTimedOut)  {
            // Send a new request in 2 sec
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self refreshSupportedAuthFlow];
            });
        }
    }
}

- (void)onReachabilityStatusChange:(NSNotification *)notif {
    AFNetworkReachabilityManager *reachabilityManager = [AFNetworkReachabilityManager sharedManager];
    AFNetworkReachabilityStatus status = reachabilityManager.networkReachabilityStatus;
    
    if (status == AFNetworkReachabilityStatusReachableViaWiFi || status == AFNetworkReachabilityStatusReachableViaWWAN) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshSupportedAuthFlow];
        });
    } else if (status == AFNetworkReachabilityStatusNotReachable) {
        _noFlowLabel.text = @"Please check your network connectivity";
    }
}

- (IBAction)onButtonPressed:(id)sender {
    [self dismissKeyboard];
    
    if (sender == _submitButton) {
        MatrixSDKHandler *matrix = [MatrixSDKHandler sharedHandler];
        if (matrix.mxRestClient) {
            // Disable user interaction to prevent multiple requests
            [self setUserInteractionEnabled:NO];
            [_activityIndicator startAnimating];
            
            if (_authType == AuthenticationTypeLogin) {
                if ([_selectedFlow.type isEqualToString:kMXLoginFlowTypePassword]) {
                    [matrix.mxRestClient loginWithUser:matrix.userLogin andPassword:_authInputsPasswordBasedView.passWordTextField.text
                                               success:^(MXCredentials *credentials){
                                                   [_activityIndicator stopAnimating];
                                                   
                                                   // Report credentials
                                                   [matrix setUserId:credentials.userId];
                                                   [matrix setAccessToken:credentials.accessToken];
                                                   // Extract homeServer name from userId
                                                   NSArray *components = [credentials.userId componentsSeparatedByString:@":"];
                                                   if (components.count == 2) {
                                                       [matrix setHomeServer:[components lastObject]];
                                                   } else {
                                                       NSLog(@"[AuthenticationVC] Warning: the userId is not correctly formatted: %@", credentials.userId);
                                                   }
                                                   
                                                   [self dismissViewControllerAnimated:YES completion:nil];
                                               }
                                               failure:^(NSError *error){
                                                   [self onFailureDuringAuthRequest:error];
                                               }];
                } else {
                    // FIXME
                    [self onFailureDuringAuthRequest:[NSError errorWithDomain:nil code:0 userInfo:@{@"error": @"Not supported yet"}]];
                }
            } else {
                // FIXME
                [self onFailureDuringAuthRequest:[NSError errorWithDomain:nil code:0 userInfo:@{@"error": @"Not supported yet"}]];
            }
        }
    } else if (sender == _authSwitchButton){
        if (_authType == AuthenticationTypeLogin) {
            self.authType = AuthenticationTypeRegister;
        } else {
            self.authType = AuthenticationTypeLogin;
        }
    } else if (sender == _retryButton) {
        [self refreshSupportedAuthFlow];
    } else if (sender == _cancelRegistrationFallbackButton) {
        // Hide fallback webview
        [self hideRegistrationFallbackView];
        self.authType = AuthenticationTypeLogin;
    }
}

- (void)onFailureDuringAuthRequest:(NSError *)error {
    [_activityIndicator stopAnimating];
    [self setUserInteractionEnabled:YES];
    
    NSLog(@"[AuthenticationVC] Auth request failed: %@", error);
    
    // translate the error code to a human message
    NSString* message = error.localizedDescription;
    NSDictionary* dict = error.userInfo;
    
    // detect if it is a Matrix SDK issue
    if (dict) {
        NSString* localizedError = [dict valueForKey:@"error"];
        NSString* errCode = [dict valueForKey:@"errcode"];
        
        if (errCode) {
            if ([errCode isEqualToString:@"M_FORBIDDEN"]) {
                message = @"Invalid username/password";
            } else if (localizedError.length > 0) {
                message = localizedError;
            } else if ([errCode isEqualToString:@"M_UNKNOWN_TOKEN"]) {
                message = @"The access token specified was not recognised";
            } else if ([errCode isEqualToString:@"M_BAD_JSON"]) {
                message = @"Malformed JSON";
            } else if ([errCode isEqualToString:@"M_NOT_JSON"]) {
                message = @"Did not contain valid JSON";
            } else if ([errCode isEqualToString:@"M_LIMIT_EXCEEDED"]) {
                message = @"Too many requests have been sent";
            } else if ([errCode isEqualToString:@"M_USER_IN_USE"]) {
                message = @"This user name is already used";
            } else if ([errCode isEqualToString:@"M_LOGIN_EMAIL_URL_NOT_YET"]) {
                message = @"The email link which has not been clicked yet";
            } else {
                message = errCode;
            }
        }
    }
    
    //Alert user
    alert = [[MXKAlert alloc] initWithTitle:@"Login Failed" message:message style:MXKAlertStyleAlert];
    [alert addActionWithTitle:@"Dismiss" style:MXKAlertActionStyleCancel handler:^(MXKAlert *alert) {}];
    [alert showInViewController:self];
}

#pragma mark - Keyboard handling

- (void)onKeyboardWillShow:(NSNotification *)notif {
    NSValue *rectVal = notif.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect endRect = rectVal.CGRectValue;
    
    UIEdgeInsets insets = self.authenticationScrollView.contentInset;
    // Handle portrait/landscape mode
    insets.bottom = (endRect.origin.y == 0) ? endRect.size.width : endRect.size.height;
    self.authenticationScrollView.contentInset = insets;
}

- (void)onKeyboardWillHide:(NSNotification *)notif {
    UIEdgeInsets insets = self.authenticationScrollView.contentInset;
    insets.bottom = 0;
    self.authenticationScrollView.contentInset = insets;
}

- (void)dismissKeyboard {
    // Hide the keyboard
    [currentAuthInputsView dismissKeyboard];
    [_homeServerTextField resignFirstResponder];
    [_identityServerTextField resignFirstResponder];
}

#pragma mark - UITextField delegate

- (void)onTextFieldChange:(NSNotification *)notif {
    NSString *homeServerURL = _homeServerTextField.text;
    
    if (currentAuthInputsView.areAllRequiredFieldsFilled && homeServerURL.length) {
        _submitButton.enabled = YES;
    } else {
        _submitButton.enabled = NO;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    if (textField == _homeServerTextField) {
        if (![[mxHandler homeServerURL] isEqualToString:textField.text]) {
            [mxHandler setHomeServerURL:textField.text];
            if (!textField.text.length) {
                // Force refresh with default value
                textField.text = [mxHandler homeServerURL];
            }
            // Refresh UI
            [self refreshSupportedAuthFlow];
        }
    }
    else if (textField == _identityServerTextField) {
        [mxHandler setIdentityServerURL:textField.text];
        if (!textField.text.length) {
            // Force refresh with default value
            textField.text = [mxHandler identityServerURL];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    if (textField.returnKeyType == UIReturnKeyDone) {
        // "Done" key has been pressed
        [textField resignFirstResponder];
    }
    return YES;
}

#pragma mark - AuthInputsViewDelegate delegate

- (void)authInputsDoneKeyHasBeenPressed:(AuthInputsView *)authInputsView {
    if (_submitButton.isEnabled) {
        // Launch authentication now
        [self onButtonPressed:_submitButton];
    }
}

#pragma mark - Registration Fallback

- (void)showRegistrationFallBackView:(NSString*)fallbackPage {
    _authenticationScrollView.hidden = YES;
    _registrationFallbackContentView.hidden = NO;
    
    [_registrationFallbackWebView openFallbackPage:fallbackPage success:^(MXCredentials *credentials) {
        // Report credentials
        MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
        [mxHandler setUserId:credentials.userId];
        [mxHandler setAccessToken:credentials.accessToken];
        // Extract homeServer name from userId
        NSArray *components = [credentials.userId componentsSeparatedByString:@":"];
        if (components.count == 2) {
            [mxHandler setHomeServer:[components lastObject]];
        } else {
            NSLog(@"[AuthenticationVC] Warning: the userId is not correctly formatted: %@", credentials.userId);
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)hideRegistrationFallbackView {
    [_registrationFallbackWebView stopLoading];
    _authenticationScrollView.hidden = NO;
    _registrationFallbackContentView.hidden = YES;
}

@end
