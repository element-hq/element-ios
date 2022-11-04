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
    private let settingsService: UserSessionSettingsProtocol
    
    var completion: ((UserSessionsOverviewViewModelResult) -> Void)?

    init(userSessionsOverviewService: UserSessionsOverviewServiceProtocol, settingsService: UserSessionSettingsProtocol) {
        self.userSessionsOverviewService = userSessionsOverviewService
        self.settingsService = settingsService
        
        super.init(initialViewState: .init(showLocationInfo: settingsService.showIPAddressesInSessionsManager))
        
        userSessionsOverviewService.overviewDataPublisher.sink { [weak self] overviewData in
            self?.updateViewState(with: overviewData)
        }
        .store(in: &cancellables)
        
        self.settingsService
            .showIPAddressesInSessionsManagerPublisher
            .weakAssign(to: \.state.showLocationInfo, on: self)
            .store(in: &cancellables)
        
        updateViewState(with: userSessionsOverviewService.overviewDataPublisher.value)
    }
    
    // MARK: - Public
    
    override func process(viewAction: UserSessionsOverviewViewAction) {
        switch viewAction {
        case .viewAppeared:
            loadData()
        case .verifyCurrentSession:
            completion?(.verifyCurrentSession)
        case .renameCurrentSession:
            guard let currentSessionInfo = userSessionsOverviewService.currentSession else {
                assertionFailure("Missing current session")
                return
            }
            completion?(.renameSession(currentSessionInfo))
        case .logoutOfCurrentSession:
            guard let currentSessionInfo = userSessionsOverviewService.currentSession else {
                assertionFailure("Missing current session")
                return
            }
            completion?(.logoutOfSession(currentSessionInfo))
        case .viewCurrentSessionDetails:
            guard let currentSessionInfo = userSessionsOverviewService.currentSession else {
                assertionFailure("Missing current session")
                return
            }
            completion?(.showCurrentSessionOverview(sessionInfo: currentSessionInfo))
        case .viewAllUnverifiedSessions:
            showSessions(filteredBy: .unverified)
        case .viewAllInactiveSessions:
            showSessions(filteredBy: .inactive)
        case .viewAllOtherSessions:
            showSessions(filteredBy: .all)
        case .tapUserSession(let sessionId):
            guard let session = userSessionsOverviewService.sessionForIdentifier(sessionId) else {
                assertionFailure("Missing session info")
                return
            }
            completion?(.showUserSessionOverview(sessionInfo: session))
        case .linkDevice:
            completion?(.linkDevice)
        case .logoutOtherSessions:
            completion?(.logoutFromUserSessions(sessionInfos: userSessionsOverviewService.otherSessions))
        case .showLocationInfo:
            settingsService.showIPAddressesInSessionsManager.toggle()
            state.showLocationInfo = settingsService.showIPAddressesInSessionsManager
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
        state.linkDeviceButtonVisible = userSessionsViewData.linkDeviceEnabled
    }
    
    private func loadData() {
        state.showLoadingIndicator = true
        
        userSessionsOverviewService.updateOverviewData { [weak self] result in
            guard let self = self else { return }
            
            self.state.showLoadingIndicator = false
            
            if case let .failure(error) = result {
                // TODO:
            }
            
            // No need to consume .success as there's a subscription on the data.
        }
    }
    
    private func showSessions(filteredBy filter: UserOtherSessionsFilter) {
        completion?(.showOtherSessions(sessionInfos: userSessionsOverviewService.otherSessions,
                                       filter: filter))
    }
}

extension Collection where Element == UserSessionInfo {
    func asViewData() -> [UserSessionListItemViewData] {
        map { UserSessionListItemViewDataFactory().create(from: $0) }
    }
}
