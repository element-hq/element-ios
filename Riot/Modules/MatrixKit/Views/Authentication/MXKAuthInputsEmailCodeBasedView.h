/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKAuthInputsView.h"

@interface MXKAuthInputsEmailCodeBasedView : MXKAuthInputsView

/**
 The input text field related to user id or user login.
 */
@property (weak, nonatomic) IBOutlet UITextField *userLoginTextField;

/**
 The input text field used to fill an email or the related token.
 */
@property (weak, nonatomic) IBOutlet UITextField *emailAndTokenTextField;

/**
 Label used to prompt user to fill the email token.
 */
@property (weak, nonatomic) IBOutlet UILabel *promptEmailTokenLabel;

/**
 The text field related to the display name. This item is displayed in case of registration.
 */
@property (weak, nonatomic) IBOutlet UITextField *displayNameTextField;

@end
