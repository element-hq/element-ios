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

import SwiftUI

typealias UserOtherSessionsViewModelType = StateStoreViewModel<UserOtherSessionsViewState, UserOtherSessionsViewAction>

class UserOtherSessionsViewModel: UserOtherSessionsViewModelType, UserOtherSessionsViewModelProtocol {
    var completion: ((UserOtherSessionsViewModelResult) -> Void)?
    private let sessionInfos: [UserSessionInfo]
    private var selectedSessions: Set<SessionId> = []
    private let defaultTitle: String
    private let settingsService: UserSessionSettingsProtocol
    
    init(sessionInfos: [UserSessionInfo],
         filter: UserOtherSessionsFilter,
         title: String,
         settingsService: UserSessionSettingsProtocol) {
        self.sessionInfos = sessionInfos
        defaultTitle = title
        let bindings = UserOtherSessionsBindings(filter: filter, isEditModeEnabled: false)
        let sessionItems = filter.filterSessionInfos(sessionInfos: sessionInfos, selectedSessions: selectedSessions)
        self.settingsService = settingsService
        super.init(initialViewState: UserOtherSessionsViewState(bindings: bindings,
                                                                title: title,
                                                                sessionItems: sessionItems,
                                                                header: filter.userOtherSessionsViewHeader,
                                                                emptyItemsTitle: filter.userOtherSessionsViewEmptyResultsTitle,
                                                                allItemsSelected: false,
                                                                enableSignOutButton: false,
                                                                showLocationInfo: settingsService.showIPAddressesInSessionsManager))
    }
    
    // MARK: - Public
    
    override func process(viewAction: UserOtherSessionsViewAction) {
        switch viewAction {
        case let .userOtherSessionSelected(sessionId: sessionId):
            if state.bindings.isEditModeEnabled {
                updateSelectionForSession(sessionId: sessionId)
                updateViewState()
            } else {
                showUserSessionOverview(sessionId: sessionId)
            }
        case .filterWasChanged:
            updateViewState()
        case .clearFilter:
            state.bindings.filter = .all
            updateViewState()
        case .editModeWasToggled:
            selectedSessions.removeAll()
            updateViewState()
        case .toggleAllSelection:
            toggleAllSelection()
            updateViewState()
        case .logoutAllUserSessions:
            let filteredSessions = state.bindings.filter.filterSessionsInfos(sessionInfos)
            completion?(.logoutFromUserSessions(sessionInfos: filteredSessions))
        case .logoutSelectedUserSessions:
            let selectedSessionInfos = sessionInfos.filter { sessionInfo in
                selectedSessions.contains(sessionInfo.id)
            }
            completion?(.logoutFromUserSessions(sessionInfos: selectedSessionInfos))
        case .showLocationInfo:
            settingsService.showIPAddressesInSessionsManager.toggle()
            state.showLocationInfo = settingsService.showIPAddressesInSessionsManager
        case .viewSessionInfo:
            completion?(.showSessionStateInfo(filter: state.bindings.filter))
        }
    }

    // MARK: - Private
    
    private func showUserSessionOverview(sessionId: String) {
        guard let session = sessionInfos.first(where: { $0.id == sessionId }) else {
            assertionFailure("Session should exist in the array.")
            return
        }
        completion?(.showUserSessionOverview(sessionInfo: session))
    }
    
    private func updateSelectionForSession(sessionId: String) {
        if selectedSessions.contains(sessionId) {
            selectedSessions.remove(sessionId)
        } else {
            selectedSessions.insert(sessionId)
        }
    }
    
    private func updateViewState() {
        let currentFilter = state.bindings.filter
        
        state.sessionItems = currentFilter.filterSessionInfos(sessionInfos: sessionInfos, selectedSessions: selectedSessions)
        state.header = currentFilter.userOtherSessionsViewHeader
        
        if state.bindings.isEditModeEnabled {
            state.title = VectorL10n.userOtherSessionSelectedCount(String(selectedSessions.count))
        } else {
            state.title = defaultTitle
        }
        
        state.emptyItemsTitle = currentFilter.userOtherSessionsViewEmptyResultsTitle
        
        state.allItemsSelected = sessionInfos.count == selectedSessions.count
        
        state.enableSignOutButton = selectedSessions.count > 0
    }
    
    private func toggleAllSelection() {
        if state.allItemsSelected {
            selectedSessions.removeAll()
        } else {
            sessionInfos.forEach { sessionInfo in
                selectedSessions.insert(sessionInfo.id)
            }
        }
    }
}

private extension UserOtherSessionsFilter {
    var userOtherSessionsViewHeader: UserOtherSessionsHeaderViewData {
        switch self {
        case .all:
            return UserOtherSessionsHeaderViewData(title: nil,
                                                   subtitle: VectorL10n.userSessionsOverviewOtherSessionsSectionInfo,
                                                   iconName: nil)
        case .inactive:
            return UserOtherSessionsHeaderViewData(title: VectorL10n.userOtherSessionFilterMenuInactive,
                                                   subtitle: VectorL10n.userSessionsOverviewSecurityRecommendationsInactiveInfo + " %@",
                                                   iconName: Asset.Images.userOtherSessionsInactive.name)
        case .unverified:
            return UserOtherSessionsHeaderViewData(title: VectorL10n.userSessionUnverifiedShort,
                                                   subtitle: VectorL10n.userOtherSessionUnverifiedSessionsHeaderSubtitle + " %@",
                                                   iconName: Asset.Images.userOtherSessionsUnverified.name)
        case .verified:
            return UserOtherSessionsHeaderViewData(title: VectorL10n.userOtherSessionFilterMenuVerified,
                                                   subtitle: VectorL10n.userOtherSessionVerifiedSessionsHeaderSubtitle + " %@",
                                                   iconName: Asset.Images.userOtherSessionsVerified.name)
        }
    }
    
    var userOtherSessionsViewEmptyResultsTitle: String {
        switch self {
        case .all:
            return ""
        case .verified:
            return VectorL10n.userOtherSessionNoVerifiedSessions
        case .unverified:
            return VectorL10n.userOtherSessionNoUnverifiedSessions
        case .inactive:
            return VectorL10n.userOtherSessionNoInactiveSessions
        }
    }
    
    func filterSessionsInfos(_ sessionInfos: [UserSessionInfo]) -> [UserSessionInfo] {
        switch self {
        case .all:
            return sessionInfos.filter { !$0.isCurrent }
        case .inactive:
            return sessionInfos.filter { !$0.isActive }
        case .unverified:
            return sessionInfos.filter { $0.verificationState.isUnverified }
        case .verified:
            return sessionInfos.filter { $0.verificationState == .verified }
        }
    }
    
    func filterSessionInfos(sessionInfos: [UserSessionInfo], selectedSessions: Set<SessionId>) -> [UserSessionListItemViewData] {
        filterSessionsInfos(sessionInfos)
            .map {
                UserSessionListItemViewDataFactory().create(from: $0,
                                                            isSelected: selectedSessions.contains($0.id))
            }
    }
}
