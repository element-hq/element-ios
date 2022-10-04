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
enum UserOtherSessionsCoordinatorResult {
    case openSessionDetails(sessionInfo: UserSessionInfo)
}

// MARK: View model

enum UserOtherSessionsViewModelResult: Equatable {
    case showUserSessionOverview(sessionInfo: UserSessionInfo)
}

// MARK: View

struct UserOtherSessionsViewState: BindableState, Equatable {
    let title: String
    var sections: [UserOtherSessionsSection]
}

enum UserOtherSessionsSection: Hashable, Identifiable {
    var id: Self {
        self
    }
    case sessionItems(header: UserOtherSessionsHeaderViewData, items: [UserSessionListItemViewData])
}

enum UserOtherSessionsViewAction {
    case userOtherSessionSelected(sessionId: String)
}
