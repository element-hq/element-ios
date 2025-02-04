//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - Coordinator

enum UserSessionsOverviewCoordinatorResult {
    case verifyCurrentSession
    case renameSession(UserSessionInfo)
    case logoutOfSession(UserSessionInfo)
    case openSessionOverview(sessionInfo: UserSessionInfo)
    case openOtherSessions(sessionInfos: [UserSessionInfo], filter: UserOtherSessionsFilter)
    case linkDevice
    case logoutFromUserSessions(sessionInfos: [UserSessionInfo])
}

// MARK: View model

enum UserSessionsOverviewViewModelResult: Equatable {
    case showOtherSessions(sessionInfos: [UserSessionInfo], filter: UserOtherSessionsFilter)
    case verifyCurrentSession
    case renameSession(UserSessionInfo)
    case logoutOfSession(UserSessionInfo)
    case showCurrentSessionOverview(sessionInfo: UserSessionInfo)
    case showUserSessionOverview(sessionInfo: UserSessionInfo)
    case linkDevice
    case logoutFromUserSessions(sessionInfos: [UserSessionInfo])
}

// MARK: View

struct UserSessionsOverviewViewState: BindableState {
    var currentSessionViewData: UserSessionCardViewData?
    var unverifiedSessionsViewData = [UserSessionListItemViewData]()
    var inactiveSessionsViewData = [UserSessionListItemViewData]()
    var otherSessionsViewData = [UserSessionListItemViewData]()
    var showLoadingIndicator = false
    var linkDeviceButtonVisible = false
    var showLocationInfo: Bool
    var showDeviceLogout: Bool
}

enum UserSessionsOverviewViewAction {
    case viewAppeared
    case verifyCurrentSession
    case renameCurrentSession
    case logoutOfCurrentSession
    case viewCurrentSessionDetails
    case viewAllUnverifiedSessions
    case viewAllInactiveSessions
    case viewAllOtherSessions
    case tapUserSession(_ sessionId: String)
    case linkDevice
    case logoutOtherSessions
    case showLocationInfo
}
