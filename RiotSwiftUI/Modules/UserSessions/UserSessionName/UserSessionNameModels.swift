//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - Coordinator

enum UserSessionNameCoordinatorResult {
    /// The user cancelled the rename operation.
    case cancel
    /// The user successfully updated the name of the session.
    case sessionNameUpdated
}

// MARK: View model

enum UserSessionNameViewModelResult {
    /// The user cancelled the rename operation.
    case cancel
    /// Update the session name to the supplied string.
    case updateName(String)
    /// The user tapped the learn more button.
    case learnMore
}

// MARK: View

struct UserSessionNameViewState: BindableState {
    var bindings: UserSessionNameBindings
    /// The current name of the session before any updates are made.
    let currentName: String
    
    /// Whether or not to allow the user to update the session name.
    var canUpdateName: Bool {
        !bindings.sessionName.isEmpty && bindings.sessionName != currentName
    }
}

struct UserSessionNameBindings {
    /// The name input by the user.
    var sessionName: String
    /// The currently displayed alert's info value otherwise `nil`.
    var alertInfo: AlertInfo<Int>?
}

enum UserSessionNameViewAction {
    /// The user tapped the done button to update the session name.
    case done
    /// The user tapped the cancel button.
    case cancel
    /// The user tapped the learn more button.
    case learnMore
}
