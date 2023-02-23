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

import Foundation

// MARK: View model

enum AuthenticationRegistrationViewModelResult: CustomStringConvertible {
    /// The user would like to select another server.
    case selectServer
    /// Validate the supplied username with the homeserver.
    case validateUsername(String)
    /// Create an account using the supplied credentials.
    case createAccount(username: String, password: String)
    /// Continue using the supplied SSO provider.
    case continueWithSSO(SSOIdentityProvider)
    /// Continue using a fallback
    case fallback
    
    /// A string representation of the result, ignoring any associated values that could leak PII.
    var description: String {
        switch self {
        case .selectServer:
            return "selectServer"
        case .validateUsername:
            return "validateUsername"
        case .createAccount:
            return "createAccount"
        case .continueWithSSO(let provider):
            return "continueWithSSO: \(provider)"
        case .fallback:
            return "fallback"
        }
    }
}

// MARK: View

struct AuthenticationRegistrationViewState: BindableState {
    enum UsernameAvailability {
        /// The availability of the username is unknown.
        case unknown
        /// The username is available.
        case available
        /// The username is invalid for the following reason.
        case invalid(String)
    }
    
    /// Data about the selected homeserver.
    var homeserver: AuthenticationHomeserverViewData
    /// Whether a new homeserver is currently being loaded.
    var isLoading = false
    /// View state that can be bound to from SwiftUI.
    var bindings: AuthenticationRegistrationBindings
    /// Whether or not the username field has been edited yet.
    ///
    /// This is used to delay showing an error state until the user has tried 1 username.
    var hasEditedUsername = false
    /// Whether or not the password field has been edited yet.
    ///
    /// This is used to delay showing an error state until the user has tried 1 password.
    var hasEditedPassword = false
    
    /// The availability of the currently enetered username.
    var usernameAvailability: UsernameAvailability = .unknown
    
    /// The message to show in the username text field footer.
    var usernameFooterMessage: String {
        switch usernameAvailability {
        case .unknown:
            return VectorL10n.authenticationRegistrationUsernameFooter
        case .invalid(let errorMessage):
            return errorMessage
        case .available:
            // https is never shown to the user but http is, so strip the scheme.
            let domain = homeserver.address.replacingOccurrences(of: "http://", with: "")
            let userID = "@\(bindings.username):\(domain)"
            return VectorL10n.authenticationRegistrationUsernameFooterAvailable(userID)
        }
    }
    
    /// Whether to show any SSO buttons.
    var showSSOButtons: Bool {
        !homeserver.ssoIdentityProviders.isEmpty
    }
    
    /// Whether the current `username` is invalid.
    var isUsernameInvalid: Bool {
        if case .invalid = usernameAvailability {
            return true
        } else {
            return bindings.username.isEmpty
        }
    }
    
    /// Whether the current `password` is invalid.
    var isPasswordInvalid: Bool {
        bindings.password.count < 8
    }
    
    /// `true` if it is possible to continue, otherwise `false`.
    var hasValidCredentials: Bool {
        !isUsernameInvalid && !isPasswordInvalid
    }
    
    /// `true` if valid credentials have been entered and the homeserver is loaded.
    var canSubmit: Bool {
        hasValidCredentials && !isLoading
    }
}

struct AuthenticationRegistrationBindings {
    /// The username input by the user.
    var username = ""
    /// The password input by the user.
    var password = ""
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<AuthenticationRegistrationErrorType>?
}

enum AuthenticationRegistrationViewAction {
    /// The user would like to select another server.
    case selectServer
    /// Validate the supplied username with the homeserver.
    case validateUsername
    /// Allows password validation to take place (sent after editing the password for the first time).
    case enablePasswordValidation
    /// Clear any availability messages being shown in the username text field footer.
    case resetUsernameAvailability
    /// Continue using the input username and password.
    case next
    /// Continue using the supplied SSO provider.
    case continueWithSSO(SSOIdentityProvider)
    /// Continue using the fallback page
    case fallback
}

enum AuthenticationRegistrationErrorType: Hashable {
    /// An error to be shown in the username text field footer.
    case usernameUnavailable(String)
    
    /// An error response from the homeserver.
    case mxError(String)
    /// The current homeserver address isn't valid.
    case invalidHomeserver
    /// The response from the homeserver was unexpected.
    case invalidResponse
    /// The homeserver doesn't support registration.
    case registrationDisabled
    /// An unknown error occurred.
    case unknown
}
