//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

// MARK: View model

enum AuthenticationVerifyEmailViewModelResult {
    /// Send an email to the associated address.
    case send(String)
    /// Send the email once more.
    case resend
    /// Cancel the flow.
    case cancel
    /// Go back to the email form
    case goBack
}

// MARK: View

struct AuthenticationVerifyEmailViewState: BindableState {
    /// The homeserver requesting email verification.
    let homeserver: AuthenticationHomeserverViewData
    /// An email has been sent and the app is waiting for the user to tap the link.
    var hasSentEmail = false
    /// View state that can be bound to from SwiftUI.
    var bindings: AuthenticationVerifyEmailBindings
    
    /// The message shown in the header while asking for an email address to be entered.
    var formHeaderMessage: String {
        VectorL10n.authenticationVerifyEmailInputMessage(homeserver.address)
    }
    
    /// Whether the email address is valid and the user can continue.
    var hasInvalidAddress: Bool {
        bindings.emailAddress.isEmpty
    }
}

struct AuthenticationVerifyEmailBindings {
    /// The email address input by the user.
    var emailAddress: String
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<AuthenticationVerifyEmailErrorType>?
}

enum AuthenticationVerifyEmailViewAction {
    /// Send an email to the entered address.
    case send
    /// Send the email once more.
    case resend
    /// Cancel the flow.
    case cancel
    /// Go back to enter email adress screen
    case goBack
}

enum AuthenticationVerifyEmailErrorType: Hashable {
    /// An error response from the homeserver.
    case mxError(String)
    /// An unknown error occurred.
    case unknown
}
