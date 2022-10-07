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
    case cancel
    case sessionNameUpdated
}

// MARK: View model

enum UserSessionNameViewModelResult {
    case updateName(String)
    case cancel
}

// MARK: View

struct UserSessionNameViewState: BindableState {
    var bindings: UserSessionNameBindings
    /// The current name of the session.
    let currentName: String
    
    /// Whether or not it is possible to update the session with the entered name.
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
    case save
    case cancel
    case learnMore
}
