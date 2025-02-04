//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

// MARK: Data

struct SoftLogoutCredentials {
    let userId: String
    let homeserverName: String
    let userDisplayName: String
    let deviceId: String?
}

// MARK: View model

enum AuthenticationSoftLogoutViewModelResult: CustomStringConvertible {
    /// Login with password
    case login(String)
    /// Forgot password
    case forgotPassword
    /// Clear all user data
    case clearAllData
    /// Continue using the supplied SSO provider.
    case continueWithSSO(SSOIdentityProvider)
    /// Continue using the fallback page
    case fallback
    
    /// A string representation of the result, ignoring any associated values that could leak PII.
    var description: String {
        switch self {
        case .login:
            return "login"
        case .forgotPassword:
            return "forgotPassword"
        case .clearAllData:
            return "clearAllData"
        case .continueWithSSO(let provider):
            return "continueWithSSO: \(provider)"
        case .fallback:
            return "fallback"
        }
    }
}

// MARK: View

struct AuthenticationSoftLogoutViewState: BindableState {
    /// Soft logout credentials
    var credentials: SoftLogoutCredentials

    /// Data about the selected homeserver.
    var homeserver: AuthenticationHomeserverViewData

    /// Flag indicating soft logged out user needs backup for some keys
    var keyBackupNeeded: Bool

    /// View state that can be bound to from SwiftUI.
    var bindings: AuthenticationSoftLogoutBindings

    /// Whether to show login form.
    var showLoginForm: Bool {
        homeserver.showLoginForm
    }

    /// Whether to show any SSO buttons.
    var showSSOButtons: Bool {
        !homeserver.ssoIdentityProviders.isEmpty
    }

    /// Whether to show recover encryption keys message
    var showRecoverEncryptionKeysMessage: Bool {
        keyBackupNeeded
    }
    
    /// Whether the password is valid and the user can continue.
    var hasInvalidPassword: Bool {
        bindings.password.isEmpty
    }
}

struct AuthenticationSoftLogoutBindings {
    /// The password input by the user.
    var password: String
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<AuthenticationSoftLogoutErrorType>?
}

enum AuthenticationSoftLogoutViewAction {
    /// Login.
    case login
    /// Forgot password
    case forgotPassword
    /// Clear all user data.
    case clearAllData
    /// Continue using the supplied SSO provider.
    case continueWithSSO(SSOIdentityProvider)
    /// Continue using the fallback page
    case fallback
}

enum AuthenticationSoftLogoutErrorType: Hashable {
    /// An error response from the homeserver.
    case mxError(String)
    /// An unknown error occurred.
    case unknown
}
