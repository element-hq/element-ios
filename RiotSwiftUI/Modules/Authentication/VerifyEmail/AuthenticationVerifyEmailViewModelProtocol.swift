//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol AuthenticationVerifyEmailViewModelProtocol {
    var callback: (@MainActor (AuthenticationVerifyEmailViewModelResult) -> Void)? { get set }
    var context: AuthenticationVerifyEmailViewModelType.Context { get }
    
    /// Updates the view to reflect that a verification email was successfully sent.
    @MainActor func updateForSentEmail()

    /// Goes back to the email form
    @MainActor func goBackToEnterEmailForm()
    
    /// Display an error to the user.
    @MainActor func displayError(_ type: AuthenticationVerifyEmailErrorType)
}
