//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

// MARK: View model

enum AuthenticationChoosePasswordViewModelResult: CustomStringConvertible {
    /// Submit with password and sign out of all devices option
    case submit(String, Bool)
    /// Cancel the flow.
    case cancel
    
    /// A string representation of the result, ignoring any associated values that could leak PII.
    var description: String {
        switch self {
        case .submit:
            return "submit"
        case .cancel:
            return "cancel"
        }
    }
}

// MARK: View

struct AuthenticationChoosePasswordViewState: BindableState {
    /// View state that can be bound to from SwiftUI.
    var bindings: AuthenticationChoosePasswordBindings
    
    /// Whether the password is valid and the user can continue.
    var hasInvalidPassword: Bool {
        bindings.password.count < 8
    }
}

struct AuthenticationChoosePasswordBindings {
    /// The password input by the user.
    var password: String
    /// The signout all devices checkbox status
    var signoutAllDevices: Bool
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<AuthenticationChoosePasswordErrorType>?
}

enum AuthenticationChoosePasswordViewAction {
    /// Send an email to the entered address.
    case submit
    /// Toggle sign out of all devices
    case toggleSignoutAllDevices
    /// Cancel the flow.
    case cancel
}

enum AuthenticationChoosePasswordErrorType: Hashable {
    /// An error response from the homeserver.
    case mxError(String)
    /// The user hasn't tapped the link in the verification email.
    case emailNotVerified
    /// An unknown error occurred.
    case unknown
}
