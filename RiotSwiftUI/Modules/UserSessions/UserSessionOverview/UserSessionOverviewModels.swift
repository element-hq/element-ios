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
