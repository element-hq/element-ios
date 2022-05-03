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
    case send(String)
    case resend
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
    
    var hasSentEmail = false
    var bindings: AuthenticationVerifyEmailBindings
    let baseGradient = Gradient (colors: Constants.gradientColors)
    
    var hasInvalidAddress: Bool {
        bindings.emailAddress.isEmpty
    }
}

struct AuthenticationVerifyEmailBindings {
    var emailAddress: String
    var alertInfo: AlertInfo<AuthenticationVerifyEmailErrorType>?
}

enum AuthenticationVerifyEmailViewAction {
    case send
    case resend
    case cancel
}

enum AuthenticationVerifyEmailErrorType: Hashable {
    case unknown
}
