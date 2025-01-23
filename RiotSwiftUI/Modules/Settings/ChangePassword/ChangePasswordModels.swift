//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

// MARK: View model

enum ChangePasswordViewModelResult: CustomStringConvertible {
    /// Submit with old and new passwords and sign out of all devices option
    case submit(oldPassword: String, newPassword: String, signoutAllDevices: Bool)
    
    /// A string representation of the result, ignoring any associated values that could leak PII.
    var description: String {
        switch self {
        case .submit:
            return "submit"
        }
    }
}

// MARK: View

struct ChangePasswordViewState: BindableState {
    /// Requirements text for the new password
    var passwordRequirements: String
    /// View state that can be bound to from SwiftUI.
    var bindings: ChangePasswordBindings
    
    /// Whether the user can submit the form: old password and new passwords should be entered
    var canSubmit: Bool {
        !bindings.oldPassword.isEmpty
            && !bindings.newPassword1.isEmpty
            && !bindings.newPassword2.isEmpty
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
    /// User entered new passwords do not match
    case passwordsDontMatch
    /// An unknown error occurred.
    case unknown
}
