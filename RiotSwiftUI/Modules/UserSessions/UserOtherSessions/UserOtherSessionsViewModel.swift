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
    
    init(sessionInfos: [UserSessionInfo],
         filter: UserOtherSessionsFilter,
         title: String) {
        self.sessionInfos = sessionInfos
        super.init(initialViewState: UserOtherSessionsViewState(bindings: UserOtherSessionsBindings(filter: filter),
                                                                title: title,
                                                                sections: []))
        updateViewState()
    }
    
    // MARK: - Public
    
    override func process(viewAction: UserOtherSessionsViewAction) {
        switch viewAction {
        case let .userOtherSessionSelected(sessionId: sessionId):
            guard let session = sessionInfos.first(where: { $0.id == sessionId }) else {
                assertionFailure("Session should exist in the array.")
                return
            }
            completion?(.showUserSessionOverview(sessionInfo: session))
        case .filterWasChanged:
            updateViewState()
        case .clearFilter:
            state.bindings.filter = .all
            updateViewState()
        }
    }
    
    // MARK: - Private
    
    private func updateViewState() {
        let sectionItems = createSectionItems(sessionInfos: sessionInfos, filter: state.bindings.filter)
        let sectionHeader = createHeaderData(filter: state.bindings.filter)
        if sectionItems.isEmpty {
            state.sections = [.emptySessionItems(header: sectionHeader,
                                                 title: noSessionsTitle(filter: state.bindings.filter))]
        } else {
            state.sections = [.sessionItems(header: sectionHeader,
                                            items: sectionItems)]
        }
    }
    
    private func createSectionItems(sessionInfos: [UserSessionInfo], filter: UserOtherSessionsFilter) -> [UserSessionListItemViewData] {
        filterSessions(sessionInfos: sessionInfos, by: filter)
            .map {
                UserSessionListItemViewDataFactory().create(from: $0,
                                                            highlightSessionDetails: filter == .unverified && $0.isCurrent)
            }
    }
    
    private func filterSessions(sessionInfos: [UserSessionInfo], by filter: UserOtherSessionsFilter) -> [UserSessionInfo] {
        switch filter {
        case .all:
            return sessionInfos.filter { !$0.isCurrent }
        case .inactive:
            return sessionInfos.filter { !$0.isActive }
        case .unverified:
            return sessionInfos.filter { $0.verificationState != .verified }
        case .verified:
            return sessionInfos.filter { $0.verificationState == .verified }
        }
    }
    
    private func createHeaderData(filter: UserOtherSessionsFilter) -> UserOtherSessionsHeaderViewData {
        switch filter {
        case .all:
            return UserOtherSessionsHeaderViewData(title: nil,
                                                   subtitle: VectorL10n.userSessionsOverviewOtherSessionsSectionInfo,
                                                   iconName: nil)
        case .inactive:
            return UserOtherSessionsHeaderViewData(title: VectorL10n.userOtherSessionFilterMenuInactive,
                                                   subtitle: VectorL10n.userSessionsOverviewSecurityRecommendationsInactiveInfo,
                                                   iconName: Asset.Images.userOtherSessionsInactive.name)
        case .unverified:
            return UserOtherSessionsHeaderViewData(title: VectorL10n.userSessionUnverifiedShort,
                                                   subtitle: VectorL10n.userOtherSessionUnverifiedSessionsHeaderSubtitle,
                                                   iconName: Asset.Images.userOtherSessionsUnverified.name)
        case .verified:
            return UserOtherSessionsHeaderViewData(title: VectorL10n.userOtherSessionFilterMenuVerified,
                                                   subtitle: VectorL10n.userOtherSessionVerifiedSessionsHeaderSubtitle,
                                                   iconName: Asset.Images.userOtherSessionsVerified.name)
        }
    }
    
    private func noSessionsTitle(filter: UserOtherSessionsFilter) -> String {
        switch filter {
        case .all:
            assertionFailure("The view is not intended to be displayed without any session")
            return ""
        case .verified:
            return VectorL10n.userOtherSessionNoVerifiedSessions
        case .unverified:
            return VectorL10n.userOtherSessionNoUnverifiedSessions
        case .inactive:
            return VectorL10n.userOtherSessionNoInactiveSessions
        }
    }
}
