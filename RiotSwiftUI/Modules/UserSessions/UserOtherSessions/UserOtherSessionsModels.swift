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
    case openSessionOverview(sessionInfo: UserSessionInfo)
    case logoutFromUserSessions(sessionInfos: [UserSessionInfo])
    case showSessionStateByFilter(filter: UserOtherSessionsFilter)
}

// MARK: View model

enum UserOtherSessionsViewModelResult: Equatable {
    case showUserSessionOverview(sessionInfo: UserSessionInfo)
    case logoutFromUserSessions(sessionInfos: [UserSessionInfo])
    case showSessionStateInfo(filter: UserOtherSessionsFilter)
}

// MARK: View

struct UserOtherSessionsViewState: BindableState, Equatable {
    var bindings: UserOtherSessionsBindings
    var title: String
    var sessionItems: [UserSessionListItemViewData]
    var header: UserOtherSessionsHeaderViewData
    var emptyItemsTitle: String
    var allItemsSelected: Bool
    var enableSignOutButton: Bool
    var showLocationInfo: Bool
}

struct UserOtherSessionsBindings: Equatable {
    var filter: UserOtherSessionsFilter
    var isEditModeEnabled: Bool
}

enum UserOtherSessionsViewAction {
    case userOtherSessionSelected(sessionId: String)
    case filterWasChanged
    case clearFilter
    case editModeWasToggled
    case toggleAllSelection
    case logoutAllUserSessions
    case logoutSelectedUserSessions
    case showLocationInfo
    case viewSessionInfo
}
