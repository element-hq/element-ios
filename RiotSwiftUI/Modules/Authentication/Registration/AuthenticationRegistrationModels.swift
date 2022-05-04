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

enum AuthenticationRegistrationViewModelResult {
    /// The user would like to select another server.
    case selectServer
    /// Validate the supplied username with the homeserver.
    case validateUsername(String)
    /// Create an account using the supplied credentials.
    case createAccount(username: String, password: String)
}

// MARK: View

struct AuthenticationRegistrationViewState: BindableState {
    /// The address of the homeserver.
    var homeserverAddress: String
    /// Whether or not to show the username and password text fields with the next button
    var showRegistrationForm: Bool
    /// An array containing the available SSO options for login.
    var ssoIdentityProviders: [SSOIdentityProvider]
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
    
    /// An error message to be shown in the username text field footer.
    var usernameErrorMessage: String?
    
    /// The message to show in the username text field footer.
    var usernameFooterMessage: String {
        usernameErrorMessage ?? VectorL10n.authenticationRegistrationUsernameFooter
    }
    
    /// A description that can be shown for the currently selected homeserver.
    var serverDescription: String? {
        guard homeserverAddress == "matrix.org" else { return nil }
        return VectorL10n.authenticationRegistrationMatrixDescription
    }
    
    /// Whether to show any SSO buttons.
    var showSSOButtons: Bool {
        !ssoIdentityProviders.isEmpty
    }
    
    /// Whether the current `username` is valid.
    var isUsernameValid: Bool {
        !bindings.username.isEmpty && usernameErrorMessage == nil
    }
    
    /// Whether the current `password` is valid.
    var isPasswordValid: Bool {
        bindings.password.count >= 8
    }
    
    /// `true` if it is possible to continue, otherwise `false`.
    var hasValidCredentials: Bool {
        isUsernameValid && isPasswordValid
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
    /// Clear any errors being shown in the username text field footer.
    case clearUsernameError
    /// Continue using the input username and password.
    case next
    /// Login using the supplied SSO provider ID.
    case continueWithSSO(id: String)
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
