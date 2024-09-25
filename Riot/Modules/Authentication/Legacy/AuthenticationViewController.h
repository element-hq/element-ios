/*
Copyright 2020-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

@protocol AuthenticationViewControllerDelegate;
@class SSOIdentityProvider;


@interface AuthenticationViewController : MXKAuthenticationViewController <MXKAuthenticationViewControllerDelegate>

// MXKAuthenticationViewController has already a `delegate` member
@property (nonatomic, weak) id<AuthenticationViewControllerDelegate> authVCDelegate;

@property (weak, nonatomic) IBOutlet UIView *optionsContainer;

@property (weak, nonatomic) IBOutlet UIButton *skipButton;
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;

@property (weak, nonatomic) IBOutlet UIView *serverOptionsContainer;
@property (weak, nonatomic) IBOutlet UIButton *customServersTickButton;
@property (weak, nonatomic) IBOutlet UIView *customServersContainer;
@property (weak, nonatomic) IBOutlet UIView *homeServerContainer;

@property (weak, nonatomic) IBOutlet UIView *homeServerSeparator;
@property (weak, nonatomic) IBOutlet UIView *identityServerSeparator;

@property (weak, nonatomic) IBOutlet UIView *softLogoutClearDataContainer;
@property (weak, nonatomic) IBOutlet UILabel *softLogoutClearDataLabel;
@property (weak, nonatomic) IBOutlet UIButton *softLogoutClearDataButton;

- (void)showCustomHomeserver:(NSString*)homeserver andIdentityServer:(NSString*)identityServer;

/// When SSO login succeeded, when SFSafariViewController is used, continue login with success parameters.
/// @param loginToken The login token provided when SSO succeeded.
/// @param txnId transaction id generated during SSO page presentation.
/// returns YES if the SSO login can be continued.
- (BOOL)continueSSOLoginWithToken:(NSString*)loginToken txnId:(NSString*)txnId;

/// Show or hide the custom server textfields.
/// @param isVisible YES to show, NO to hide.
- (void)setCustomServerFieldsVisible:(BOOL)isVisible;

@end


@protocol AuthenticationViewControllerDelegate <NSObject>

/**
 Notifies the delegate that authentication has succeeded.
 @param authenticationViewController The view controller that handled the authentication.
 @param session The session for the authenticated account.
 @param password Optional password used for authentication (to be handed to the verification flow).
 @param identityProvider Optional SSO identity provider used for authentication.
 */
- (void)authenticationViewController:(AuthenticationViewController * _Nonnull)authenticationViewController
                 didLoginWithSession:(MXSession *)session
                         andPassword:(NSString * _Nullable)password
               orSSOIdentityProvider:(SSOIdentityProvider * _Nullable)identityProvider;

/**
 Notifies the delegate that the user would like to clear all data following a soft logout.
 @param authenticationViewController The view controller that the user was shown.
 */
- (void)authenticationViewControllerDidRequestClearAllData:(AuthenticationViewController * _Nonnull)authenticationViewController;
@end;
