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
