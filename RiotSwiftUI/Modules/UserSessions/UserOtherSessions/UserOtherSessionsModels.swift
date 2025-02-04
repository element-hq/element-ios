//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    var showDeviceLogout: Bool
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
