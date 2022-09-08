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

// MARK: View model

enum UserSessionsOverviewViewModelResult {
    case cancel
    case showAllUnverifiedSessions
    case showAllInactiveSessions
    case verifyCurrentSession
    case showCurrentSessionDetails
    case showAllOtherSessions
    case showUserSessionDetails(_ sessionId: String)
}

// MARK: View

struct UserSessionsOverviewViewState: BindableState {
    
    var unverifiedSessionsViewData: [UserSessionListItemViewData]
    
    var inactiveSessionsViewData: [UserSessionListItemViewData]
    
    var currentSessionViewData: UserSessionCardViewData?
    
    var otherSessionsViewData: [UserSessionListItemViewData]
    
    var showLoadingIndicator: Bool = false
}

enum UserSessionsOverviewViewAction {
    case viewAppeared
    case verifyCurrentSession
    case viewCurrentSessionDetails
    case viewAllUnverifiedSessions
    case viewAllInactiveSessions
    case viewAllOtherSessions
    case tapUserSession(_ sessionId: String)
}
