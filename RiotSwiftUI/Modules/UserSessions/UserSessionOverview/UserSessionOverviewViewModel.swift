//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias UserSessionOverviewViewModelType = StateStoreViewModel<UserSessionOverviewViewState, UserSessionOverviewViewAction>

class UserSessionOverviewViewModel: UserSessionOverviewViewModelType, UserSessionOverviewViewModelProtocol {
    private let sessionInfo: UserSessionInfo
    private let service: UserSessionOverviewServiceProtocol
    private let settingService: UserSessionSettingsProtocol

    var completion: ((UserSessionOverviewViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init(sessionInfo: UserSessionInfo,
         service: UserSessionOverviewServiceProtocol,
         settingsService: UserSessionSettingsProtocol,
         sessionsOverviewDataPublisher: CurrentValueSubject<UserSessionsOverviewData, Never> = .init(.init(currentSession: nil,
                                                                                                           unverifiedSessions: [],
                                                                                                           inactiveSessions: [],
                                                                                                           otherSessions: [],
                                                                                                           linkDeviceEnabled: false))) {
        self.sessionInfo = sessionInfo
        self.service = service
        self.settingService = settingsService
        
        let cardViewData = UserSessionCardViewData(sessionInfo: sessionInfo)
        let state = UserSessionOverviewViewState(cardViewData: cardViewData,
                                                 isCurrentSession: sessionInfo.isCurrent,
                                                 isPusherEnabled: service.pusherEnabledSubject.value,
                                                 remotelyTogglingPushersAvailable: service.remotelyTogglingPushersAvailableSubject.value,
                                                 showLoadingIndicator: false,
                                                 showLocationInfo: settingsService.showIPAddressesInSessionsManager)
        super.init(initialViewState: state)
        
        startObservingService()
        
        sessionsOverviewDataPublisher.sink { [weak self] overviewData in
            guard let self = self else { return }
            
            var updatedInfo: UserSessionInfo?
            if let currentSession = overviewData.currentSession, currentSession.id == sessionInfo.id {
                updatedInfo = currentSession
            } else if let otherSession = overviewData.otherSessions.first(where: { $0.id == sessionInfo.id }) {
                updatedInfo = otherSession
            }
            
            guard let updatedInfo = updatedInfo else { return }
            self.state.cardViewData = UserSessionCardViewData(sessionInfo: updatedInfo)
        }
        .store(in: &cancellables)
    }
    
    private func startObservingService() {
        service
            .pusherEnabledSubject
            .sink(receiveValue: { [weak self] pushEnabled in
                self?.state.showLoadingIndicator = false
                self?.state.isPusherEnabled = pushEnabled
            })
            .store(in: &cancellables)
        
        service
            .remotelyTogglingPushersAvailableSubject
            .sink(receiveValue: { [weak self] remotelyTogglingPushersAvailable in
                self?.state.remotelyTogglingPushersAvailable = remotelyTogglingPushersAvailable
            })
            .store(in: &cancellables)
    }

    // MARK: - Public
    
    override func process(viewAction: UserSessionOverviewViewAction) {
        switch viewAction {
        case .verifySession:
            completion?(.verifySession(sessionInfo))
        case .viewSessionDetails:
            completion?(.showSessionDetails(sessionInfo: sessionInfo))
        case .togglePushNotifications:
            state.showLoadingIndicator = true
            service.togglePushNotifications()
        case .renameSession:
            completion?(.renameSession(sessionInfo))
        case .logoutOfSession:
            completion?(.logoutOfSession(sessionInfo))
        case .showLocationInfo:
            settingService.showIPAddressesInSessionsManager.toggle()
            state.showLocationInfo = settingService.showIPAddressesInSessionsManager
        case .viewSessionInfo:
            completion?(.showSessionStateInfo(sessionInfo))
        }
    }
}
