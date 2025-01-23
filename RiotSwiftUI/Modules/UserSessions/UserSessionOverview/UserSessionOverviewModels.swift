//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - Coordinator

enum UserSessionOverviewCoordinatorResult {
    case openSessionDetails(sessionInfo: UserSessionInfo)
    case verifySession(UserSessionInfo)
    case renameSession(UserSessionInfo)
    case logoutOfSession(UserSessionInfo)
    case showSessionStateInfo(UserSessionInfo)
}

// MARK: View model

enum UserSessionOverviewViewModelResult: Equatable {
    case showSessionDetails(sessionInfo: UserSessionInfo)
    case verifySession(UserSessionInfo)
    case renameSession(UserSessionInfo)
    case logoutOfSession(UserSessionInfo)
    case showSessionStateInfo(UserSessionInfo)
}

// MARK: View

struct UserSessionOverviewViewState: BindableState {
    var cardViewData: UserSessionCardViewData
    let isCurrentSession: Bool
    var isPusherEnabled: Bool?
    var remotelyTogglingPushersAvailable: Bool
    var showLoadingIndicator: Bool
    var showLocationInfo: Bool
}

enum UserSessionOverviewViewAction {
    case verifySession
    case viewSessionDetails
    case togglePushNotifications
    case renameSession
    case logoutOfSession
    case showLocationInfo
    case viewSessionInfo
}
