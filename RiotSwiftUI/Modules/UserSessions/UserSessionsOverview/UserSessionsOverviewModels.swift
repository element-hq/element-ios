//
// Copyright 2022 New Vector Ltd
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

enum UserSessionsOverviewCoordinatorResult {
    case renameSession(UserSessionInfo)
    case logoutOfSession(UserSessionInfo)
    case openSessionOverview(sessionInfo: UserSessionInfo)
    case openOtherSessions(sessionsInfo: [UserSessionInfo], filter: OtherUserSessionsFilter)
}

// MARK: View model

enum UserSessionsOverviewViewModelResult: Equatable {
    case showOtherSessions(sessionsInfo: [UserSessionInfo], filter: OtherUserSessionsFilter)
    case verifyCurrentSession
    case renameSession(UserSessionInfo)
    case logoutOfSession(UserSessionInfo)
    case showCurrentSessionOverview(sessionInfo: UserSessionInfo)
    case showUserSessionOverview(sessionInfo: UserSessionInfo)
}

// MARK: View

struct UserSessionsOverviewViewState: BindableState {
    var currentSessionViewData: UserSessionCardViewData?
    
    var unverifiedSessionsViewData = [UserSessionListItemViewData]()
    
    var inactiveSessionsViewData = [UserSessionListItemViewData]()
    
    var otherSessionsViewData = [UserSessionListItemViewData]()
    
    var showLoadingIndicator = false
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
}
