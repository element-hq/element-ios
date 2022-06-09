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

enum ChangePasswordViewModelResult {
    /// Submit with old and new passwords and sign out of all devices option
    case submit(String, String, Bool)
}

// MARK: View

struct ChangePasswordViewState: BindableState {
    /// View state that can be bound to from SwiftUI.
    var bindings: ChangePasswordBindings
    
    /// Whether the user can submit the form: old password should be entered, and new passwords should match
    var canSubmit: Bool {
        !bindings.oldPassword.isEmpty
        && !bindings.newPassword1.isEmpty
        && bindings.newPassword1 == bindings.newPassword2
    }
}

struct ChangePasswordBindings {
    /// The password input by the user.
    var oldPassword: String
    /// The new password input by the user.
    var newPassword1: String
    /// The new password confirmation input by the user.
    var newPassword2: String
    /// The signout all devices checkbox status
    var signoutAllDevices: Bool
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<ChangePasswordErrorType>?
}

enum ChangePasswordViewAction {
    /// Send an email to the entered address.
    case submit
    /// Toggle sign out of all devices
    case toggleSignoutAllDevices
}

enum ChangePasswordErrorType: Hashable {
    /// An error response from the homeserver.
    case mxError(String)
    /// An unknown error occurred.
    case unknown
}
