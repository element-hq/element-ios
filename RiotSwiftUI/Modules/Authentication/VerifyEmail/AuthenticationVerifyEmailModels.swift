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

enum AuthenticationVerifyEmailViewModelResult {
    /// Send an email to the associated address.
    case send(String)
    /// Send the email once more.
    case resend
    /// Cancel the flow.
    case cancel
}

// MARK: View

struct AuthenticationVerifyEmailViewState: BindableState {
    enum Constants {
        static let gradientColors = [
            Color(red: 0.646, green: 0.95, blue: 0.879),
            Color(red: 0.576, green: 0.929, blue: 0.961),
            Color(red: 0.874, green: 0.82, blue: 1)
        ]
    }
    
    /// The background gradient used with light mode.
    let gradient = Gradient (colors: Constants.gradientColors)
    /// An email has been sent and the app is waiting for the user to tap the link.
    var hasSentEmail = false
    /// View state that can be bound to from SwiftUI.
    var bindings: AuthenticationVerifyEmailBindings
    
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
}

enum AuthenticationVerifyEmailErrorType: Hashable {
    /// An error response from the homeserver.
    case mxError(String)
    /// An unknown error occurred.
    case unknown
}
