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

typealias UserSessionsOverviewViewModelType = StateStoreViewModel<UserSessionsOverviewViewState,
                                                                 Never,
                                                                 UserSessionsOverviewViewAction>

class UserSessionsOverviewViewModel: UserSessionsOverviewViewModelType, UserSessionsOverviewViewModelProtocol {

    // MARK: - Properties

    // MARK: Private

    private let userSessionsOverviewService: UserSessionsOverviewServiceProtocol

    // MARK: Public

    var completion: ((UserSessionsOverviewViewModelResult) -> Void)?

    // MARK: - Setup

    init(userSessionsOverviewService: UserSessionsOverviewServiceProtocol) {
        self.userSessionsOverviewService = userSessionsOverviewService
        
        let initialViewState = UserSessionsOverviewViewState(unverifiedSessionsViewData: [], inactiveSessionsViewData: [], currentSessionViewData: nil, otherSessionsViewData: [])
        
        super.init(initialViewState: initialViewState)
        
        self.updateViewState(with: userSessionsOverviewService.lastOverviewData)
    }
    
    // MARK: - Public

    override func process(viewAction: UserSessionsOverviewViewAction) {
        switch viewAction {
        case .viewAppeared:
            self.loadData()
        case .verifyCurrentSession:
            self.completion?(.verifyCurrentSession)
        case .viewCurrentSessionDetails:
            self.completion?(.showCurrentSessionDetails)
        case .viewAllUnverifiedSessions:
            self.completion?(.showAllUnverifiedSessions)
        case .viewAllInactiveSessions:
            self.completion?(.showAllInactiveSessions)
        case .viewAllOtherSessions:
            self.completion?(.showAllOtherSessions)
        case .tapUserSession(let sessionId):
            self.completion?(.showUserSessionDetails(sessionId))
        }
    }
    
    // MARK: - Private
    
    private func updateViewState(with userSessionsViewData: UserSessionsOverviewData) {
        
        let unverifiedSessionsViewData = self.userSessionListItemViewDataList(from: userSessionsViewData.unverifiedSessionsInfo)
        let inactiveSessionsViewData = self.userSessionListItemViewDataList(from: userSessionsViewData.inactiveSessionsInfo)
        
        var currentSessionViewData: UserSessionCardViewData?
        
        let otherSessionsViewData = self.userSessionListItemViewDataList(from: userSessionsViewData.otherSessionsInfo)
         
        
        if let currentSessionInfo = userSessionsViewData.currentSessionInfo {
            currentSessionViewData = UserSessionCardViewData(userSessionInfo: currentSessionInfo, isCurrentSessionDisplayMode: true)
        }
     
        self.state.unverifiedSessionsViewData = unverifiedSessionsViewData
        self.state.inactiveSessionsViewData = inactiveSessionsViewData
        self.state.currentSessionViewData = currentSessionViewData
        self.state.otherSessionsViewData = otherSessionsViewData
    }

    private func userSessionListItemViewDataList(from userSessionInfoList: [UserSessionInfo]) -> [UserSessionListItemViewData] {
        return userSessionInfoList.map {
            return UserSessionListItemViewData(userSessionInfo: $0)
        }
    }
    
    private func loadData() {
        
        self.state.showLoadingIndicator = true
        
        self.userSessionsOverviewService.fetchUserSessionsOverviewData { [weak self] result in
            guard let self = self else {
                return
            }
            
            self.state.showLoadingIndicator = false
            
            switch result {
            case .success(let overViewData):
                self.updateViewState(with: overViewData)
            case .failure(let error):
                // TODO
                break
            }
        }
    }
}
