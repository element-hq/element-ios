/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKAuthInputsView.h"

@interface MXKAuthInputsPasswordBasedView : MXKAuthInputsView

/**
 The input text field related to user id or user login.
 */
@property (weak, nonatomic) IBOutlet UITextField *userLoginTextField;

/**
 The input text field used to fill the password.
 */
@property (weak, nonatomic) IBOutlet UITextField *passWordTextField;

/**
 The input text field used to fill an email. This item is optional, it is added in case of registration.
 */
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;

/**
 Label used to display email field information.
 */
@property (weak, nonatomic) IBOutlet UILabel *emailInfoLabel;

/**
 The text field related to the display name. This item is displayed in case of registration.
 */
@property (weak, nonatomic) IBOutlet UITextField *displayNameTextField;

@end
