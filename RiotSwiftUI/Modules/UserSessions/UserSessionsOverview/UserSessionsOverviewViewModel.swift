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

import SwiftUI

typealias UserSessionsOverviewViewModelType = StateStoreViewModel<UserSessionsOverviewViewState, UserSessionsOverviewViewAction>

class UserSessionsOverviewViewModel: UserSessionsOverviewViewModelType, UserSessionsOverviewViewModelProtocol {
    private let userSessionsOverviewService: UserSessionsOverviewServiceProtocol

    var completion: ((UserSessionsOverviewViewModelResult) -> Void)?

    init(userSessionsOverviewService: UserSessionsOverviewServiceProtocol) {
        self.userSessionsOverviewService = userSessionsOverviewService
        
        super.init(initialViewState: .init())
        
        updateViewState(with: userSessionsOverviewService.overviewData)
    }
    
    // MARK: - Public
    
    override func process(viewAction: UserSessionsOverviewViewAction) {
        switch viewAction {
        case .viewAppeared:
            loadData()
        case .verifyCurrentSession:
            completion?(.verifyCurrentSession)
        case .renameCurrentSession:
            guard let currentSessionInfo = userSessionsOverviewService.overviewData.currentSession else {
                assertionFailure("Missing current session")
                return
            }
            completion?(.renameSession(currentSessionInfo))
        case .logoutOfCurrentSession:
            guard let currentSessionInfo = userSessionsOverviewService.overviewData.currentSession else {
                assertionFailure("Missing current session")
                return
            }
            completion?(.logoutOfSession(currentSessionInfo))
        case .viewCurrentSessionDetails:
            guard let currentSessionInfo = userSessionsOverviewService.overviewData.currentSession else {
                assertionFailure("Missing current session")
                return
            }
            completion?(.showCurrentSessionOverview(sessionInfo: currentSessionInfo))
        case .viewAllUnverifiedSessions:
            // TODO: showSessions(filteredBy: .unverified)
            break
        case .viewAllInactiveSessions:
            showSessions(filteredBy: .inactive)
        case .viewAllOtherSessions:
            // TODO: showSessions(filteredBy: .all)
            break
        case .tapUserSession(let sessionId):
            guard let session = userSessionsOverviewService.sessionForIdentifier(sessionId) else {
                assertionFailure("Missing session info")
                return
            }
            completion?(.showUserSessionOverview(sessionInfo: session))
        }
    }
    
    // MARK: - Private
    
    private func updateViewState(with userSessionsViewData: UserSessionsOverviewData) {
        state.unverifiedSessionsViewData = userSessionsViewData.unverifiedSessions.asViewData()
        state.inactiveSessionsViewData = userSessionsViewData.inactiveSessions.asViewData()
        state.otherSessionsViewData = userSessionsViewData.otherSessions.asViewData()
        
        if let currentSessionInfo = userSessionsViewData.currentSession {
            state.currentSessionViewData = UserSessionCardViewData(sessionInfo: currentSessionInfo)
        }
    }
    
    private func loadData() {
        state.showLoadingIndicator = true
        
        userSessionsOverviewService.updateOverviewData { [weak self] result in
            guard let self = self else {
                return
            }
            
            self.state.showLoadingIndicator = false
            
            switch result {
            case .success(let overViewData):
                self.updateViewState(with: overViewData)
            case .failure(let error):
                // TODO:
                break
            }
        }
    }
    
    private func showSessions(filteredBy filter: OtherUserSessionsFilter) {
        completion?(.showOtherSessions(sessionsInfo: userSessionsOverviewService.overviewData.otherSessions,
                                       filter: filter))
    }
}

extension Collection where Element == UserSessionInfo {
    func asViewData() -> [UserSessionListItemViewData] {
        map { UserSessionListItemViewDataFactory().create(from: $0)}
    }
}
