// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
