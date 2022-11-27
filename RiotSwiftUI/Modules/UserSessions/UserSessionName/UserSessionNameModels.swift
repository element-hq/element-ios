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
