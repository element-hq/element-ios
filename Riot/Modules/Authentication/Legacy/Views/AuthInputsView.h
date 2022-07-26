/*
 Copyright 2016 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
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

#import "MatrixKit.h"

@class TermsView;

@interface AuthInputsView : MXKAuthInputsView
@property (weak, nonatomic) IBOutlet UITextField *userLoginTextField;
@property (weak, nonatomic) IBOutlet UITextField *passWordTextField;
@property (weak, nonatomic) IBOutlet UITextField *repeatPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;

@property (weak, nonatomic) IBOutlet UIView *userLoginContainer;
@property (weak, nonatomic) IBOutlet UIView *emailContainer;
@property (weak, nonatomic) IBOutlet UIView *phoneContainer;
@property (weak, nonatomic) IBOutlet UIView *passwordContainer;
@property (weak, nonatomic) IBOutlet UIView *repeatPasswordContainer;

@property (weak, nonatomic) IBOutlet UIView *userLoginSeparator;
@property (weak, nonatomic) IBOutlet UIView *emailSeparator;
@property (weak, nonatomic) IBOutlet UIView *phoneSeparator;
@property (weak, nonatomic) IBOutlet UIView *passwordSeparator;
@property (weak, nonatomic) IBOutlet UIView *repeatPasswordSeparator;

@property (weak, nonatomic) IBOutlet UIButton *countryCodeButton;
@property (weak, nonatomic) IBOutlet UILabel *isoCountryCodeLabel;
@property (weak, nonatomic) IBOutlet UILabel *callingCodeLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *userLoginContainerTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordContainerTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *emailContainerTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *phoneContainerTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageLabelTopConstraint;

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

@property (weak, nonatomic) IBOutlet UIView *recaptchaContainer;
@property (weak, nonatomic) IBOutlet TermsView *termsView;

@property (weak, nonatomic) IBOutlet TermsView *ssoButtonContainer;
@property (weak, nonatomic) IBOutlet UIButton *ssoButton;

/**
 Tell whether some third-party identifiers may be added during the account registration.
 */
@property (nonatomic, readonly) BOOL areThirdPartyIdentifiersSupported;

/**
 Tell whether at least one third-party identifier is required to create a new account.
 */
@property (nonatomic, readonly) BOOL isThirdPartyIdentifierRequired;

/**
 Tell whether all the supported third-party identifiers are required to create a new account.
 */
@property (nonatomic, readonly) BOOL areAllThirdPartyIdentifiersRequired;

/**
 Update the registration inputs layout by hidding the third-party identifiers fields (YES by default).
 Set NO to show these fields and hide the others.
 */
@property (nonatomic, getter=isThirdPartyIdentifiersHidden) BOOL thirdPartyIdentifiersHidden;

/**
 Tell whether a second third-party identifier is waiting for being added to the new account.
 */
@property (nonatomic, readonly) BOOL isThirdPartyIdentifierPending;

/**
 Tell whether the flow requires a Single-Sign-On flow.
 */
@property (nonatomic, readonly) BOOL isSingleSignOnRequired;

/**
 The current selected country code
 */
@property (nonatomic) NSString *isoCountryCode;

- (IBAction)textFieldDidChange:(id)sender;

- (void)resetThirdPartyIdentifiers;

@end
