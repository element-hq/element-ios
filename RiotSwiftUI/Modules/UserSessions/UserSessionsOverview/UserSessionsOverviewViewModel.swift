//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

typealias UserSessionsOverviewViewModelType = StateStoreViewModel<UserSessionsOverviewViewState, UserSessionsOverviewViewAction>

class UserSessionsOverviewViewModel: UserSessionsOverviewViewModelType, UserSessionsOverviewViewModelProtocol {
    private let userSessionsOverviewService: UserSessionsOverviewServiceProtocol
    private let settingsService: UserSessionSettingsProtocol
    
    var completion: ((UserSessionsOverviewViewModelResult) -> Void)?

    init(userSessionsOverviewService: UserSessionsOverviewServiceProtocol, settingsService: UserSessionSettingsProtocol, showDeviceLogout: Bool) {
        self.userSessionsOverviewService = userSessionsOverviewService
        self.settingsService = settingsService
        
        super.init(initialViewState: .init(showLocationInfo: settingsService.showIPAddressesInSessionsManager, showDeviceLogout: showDeviceLogout))
        
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
