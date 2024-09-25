/*
Copyright 2024 New Vector Ltd.
Copyright 2019 The Matrix.org Foundation C.I.C
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

#import "MXKViewController.h"

#import "MXKAuthInputsView.h"
#import "MXKAuthenticationFallbackWebView.h"

@class MXKAuthenticationViewController;

/**
 `MXKAuthenticationViewController` delegate.
 */
@protocol MXKAuthenticationViewControllerDelegate <NSObject>

/**
 Tells the delegate the authentication process succeeded to add a new account.
 
 @param authenticationViewController the `MXKAuthenticationViewController` instance.
 @param userId the user id of the new added account.
 */
- (void)authenticationViewController:(MXKAuthenticationViewController *)authenticationViewController didLogWithUserId:(NSString*)userId;

@end

/**
 This view controller should be used to manage registration or login flows with matrix homeserver.
 
 Only the flow based on password is presently supported. Other flows should be added later.
 
 You may add a delegate to be notified when a new account has been added successfully.
 */
@interface MXKAuthenticationViewController : MXKViewController <UITextFieldDelegate, MXKAuthInputsViewDelegate>
{
@protected
    
    /**
     Reference to any opened alert view.
     */
    UIAlertController *alert;
    
    /**
     Tell whether the password has been reseted with success.
     Used to return on login screen on submit button pressed.
     */
    BOOL isPasswordReseted;
}

@property (weak, nonatomic) IBOutlet UIImageView *welcomeImageView;

@property (strong, nonatomic) IBOutlet UIScrollView *authenticationScrollView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *authScrollViewBottomConstraint;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UILabel *subTitleLabel;

@property (weak, nonatomic) IBOutlet UIView *authInputsContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *authInputContainerViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *authInputContainerViewMinHeightConstraint;

@property (weak, nonatomic) IBOutlet UILabel *homeServerLabel;
@property (weak, nonatomic) IBOutlet UITextField *homeServerTextField;
@property (weak, nonatomic) IBOutlet UILabel *homeServerInfoLabel;
@property (weak, nonatomic) IBOutlet UIView *identityServerContainer;
@property (weak, nonatomic) IBOutlet UILabel *identityServerLabel;
@property (weak, nonatomic) IBOutlet UITextField *identityServerTextField;
@property (weak, nonatomic) IBOutlet UILabel *identityServerInfoLabel;

@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UIButton *authSwitchButton;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *authenticationActivityIndicator;
@property (weak, nonatomic) IBOutlet UIView *authenticationActivityIndicatorContainerView;
@property (weak, nonatomic) IBOutlet UILabel *noFlowLabel;
@property (weak, nonatomic) IBOutlet UIButton *retryButton;

@property (weak, nonatomic) IBOutlet UIView *authFallbackContentView;
//  WKWebView is not available to be created from xib because of NSCoding support below iOS 11. So we're using a container view.
// See this: https://stackoverflow.com/questions/46221577/xcode-9-gm-wkwebview-nscoding-support-was-broken-in-previous-versions
@property (weak, nonatomic) IBOutlet UIView *authFallbackWebViewContainer;
@property (strong, nonatomic) MXKAuthenticationFallbackWebView *authFallbackWebView;
@property (weak, nonatomic) IBOutlet UIButton *cancelAuthFallbackButton;

/**
 The current authentication type (MXKAuthenticationTypeLogin by default).
 */
@property (nonatomic) MXKAuthenticationType authType;

/**
 The view in which authentication inputs are displayed (`MXKAuthInputsView-inherited` instance).
 */
@property (nonatomic) MXKAuthInputsView *authInputsView;

/**
 The default homeserver url (nil by default).
 */
@property (nonatomic) NSString *defaultHomeServerUrl;

/**
 The default identity server url (nil by default).
 */
@property (nonatomic) NSString *defaultIdentityServerUrl;

/**
 Force a registration process based on a predefined set of parameters.
 Use this property to pursue a registration from the next_link sent in an email validation email.
 */
@property (nonatomic) NSDictionary* externalRegistrationParameters;

/**
 Use a login process based on the soft logout credentials.
 */
@property (nonatomic) MXCredentials *softLogoutCredentials;

/**
 Enable/disable overall the user interaction option.
 It is used during authentication process to prevent multiple requests.
 */
@property(nonatomic,getter=isUserInteractionEnabled) BOOL userInteractionEnabled;

/**
 The device name used to display it in the user's devices list (nil by default).
 If nil, the device display name field is filled with a default string: "Mobile", "Tablet"...
 */
@property (nonatomic) NSString *deviceDisplayName;

/**
 The delegate for the view controller.
 */
@property (nonatomic, weak) id<MXKAuthenticationViewControllerDelegate> delegate;

/**
 current ongoing MXHTTPOperation. Nil if none.
 */
@property (nonatomic, nullable, readonly) MXHTTPOperation *currentHttpOperation;

/**
 Returns the `UINib` object initialized for a `MXKAuthenticationViewController`.
 
 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 
 @discussion You may override this method to provide a customized nib. If you do,
 you should also override `authenticationViewController` to return your
 view controller loaded from your custom nib.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `MXKAuthenticationViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 
 @return An initialized `MXKAuthenticationViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)authenticationViewController;

/**
 Register the MXKAuthInputsView class that will be used to display inputs for an authentication type.
 
 By default the 'MXKAuthInputsPasswordBasedView' class is registered for 'MXKAuthenticationTypeLogin' authentication.
 No class is registered for 'MXKAuthenticationTypeRegister' type.
 No class is registered for 'MXKAuthenticationTypeForgotPassword' type.
 
 @param authInputsViewClass a MXKAuthInputsView-inherited class.
 @param authType the concerned authentication type
 */
- (void)registerAuthInputsViewClass:(Class)authInputsViewClass forAuthType:(MXKAuthenticationType)authType;

/**
 Refresh login/register mechanism supported by the server and the application.
 */
- (void)refreshAuthenticationSession;

/**
 Handle supported flows and associated information returned by the homeserver.
 @param authSession The session to be handled.
 @param fallbackSSOFlow A fallback SSO flow to be shown when the session has none
 e.g. A login SSO flow that can be shown for a registration session.
 */
- (void)handleAuthenticationSession:(MXAuthenticationSession *)authSession withFallbackSSOFlow:(MXLoginSSOFlow *)fallbackSSOFlow;

/**
 Customize the MXHTTPClientOnUnrecognizedCertificate block that will be used to handle unrecognized certificate observed during authentication challenge from a server.
 By default we prompt the user by displaying a fingerprint (SHA256) of the certificate. The user is then able to trust or not the certificate.
 
 @param onUnrecognizedCertificateBlock the block that will be used to handle unrecognized certificate
 */
- (void)setOnUnrecognizedCertificateBlock:(MXHTTPClientOnUnrecognizedCertificate)onUnrecognizedCertificateBlock;

/**
 Check whether the current username is already in use.
 
 @param callback A block object called when the operation is completed.
 */
- (void)isUserNameInUse:(void (^)(BOOL isUserNameInUse))callback;

/**
 Make a ping to the registration endpoint to detect a possible registration problem earlier.

 @param callback A block object called when the operation is completed.
                 It provides a MXError to check to verify if the user can be registered.
 */
- (void)testUserRegistration:(void (^)(MXError *mxError))callback;

/**
 Searches an array of `MXLoginFlow` returning the first valid `MXLoginSSOFlow` found.
 */
- (MXLoginSSOFlow*)loginSSOFlowWithProvidersFromFlows:(NSArray<MXLoginFlow*>*)loginFlows;

/**
 Action registered on the following events:
 - 'UIControlEventTouchUpInside' for each UIButton instance.
 - 'UIControlEventValueChanged' for each UISwitch instance.
 */
- (IBAction)onButtonPressed:(id)sender;

/**
 Set the homeserver url and force a new authentication session.
 The default homeserver url is used when the provided url is nil.
 
 @param homeServerUrl the homeserver url to use
 */
- (void)setHomeServerTextFieldText:(NSString *)homeServerUrl;

/**
 Set the identity server url.
 The default identity server url is used when the provided url is nil.
 
 @param identityServerUrl the identity server url to use
 */
- (void)setIdentityServerTextFieldText:(NSString *)identityServerUrl;

/**
 Fetch the identity server from the wellknown API of the selected homeserver.
 and check if the HS requires an identity server.
 */
- (void)checkIdentityServer;

/**
 Force dismiss keyboard
 */
- (void)dismissKeyboard;

/**
 Cancel the current operation, and return to the initial step
 */
- (void)cancel;

/**
 Handle the error received during an authentication request.
 
 @param error the received error.
 */
- (void)onFailureDuringAuthRequest:(NSError *)error;


/**
 Display a kMXErrCodeStringResourceLimitExceeded error received during an authentication
 request.

 @param errorDict the error data.
 @param onAdminContactTapped a callback indicating if the user wants to contact their admin.
 */
- (void)showResourceLimitExceededError:(NSDictionary *)errorDict onAdminContactTapped:(void (^)(NSURL *adminContact))onAdminContactTapped;

/**
 Handle the successful authentication request.
 
 @param credentials the user's credentials.
 */
- (void)onSuccessfulLogin:(MXCredentials*)credentials;

/// Login with custom parameters
/// @param parameters Login parameters
- (void)loginWithParameters:(NSDictionary*)parameters;

/// Create an account with the given credentials
/// @param credentials Account credentials
- (void)createAccountWithCredentials:(MXCredentials *)credentials;

#pragma mark - Authentication Fallback

/**
 Display the fallback URL within a webview.
 */
- (void)showAuthenticationFallBackView;

@end

