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

enum OtherUserSessionsFilter {
    case all
    case inactive
    case unverified
}

class UserOtherSessionsViewModel: UserOtherSessionsViewModelType, UserOtherSessionsViewModelProtocol {
    
    var completion: ((UserOtherSessionsViewModelResult) -> Void)?
    private let sessionInfos: [UserSessionInfo]
    
    init(sessionInfos: [UserSessionInfo],
         filter: OtherUserSessionsFilter,
         title: String) {
        self.sessionInfos = sessionInfos
        super.init(initialViewState: UserOtherSessionsViewState(title: title, sections: []))
        updateViewState(sessionInfos: sessionInfos, filter: filter)
    }
    
    // MARK: - Public
    
    override func process(viewAction: UserOtherSessionsViewAction) {
        switch viewAction {
        case let .userOtherSessionSelected(sessionId: sessionId):
            guard let session = sessionInfos.first(where: {$0.id == sessionId}) else {
                assertionFailure("Session should exist in the array.")
                return
            }
            completion?(.showUserSessionOverview(sessionInfo: session))
        }
    }
    
    // MARK: - Private
    
    private func updateViewState(sessionInfos: [UserSessionInfo], filter: OtherUserSessionsFilter) {
        let sectionItems = createSectionItems(sessionInfos: sessionInfos, filter: filter)
        let sectionHeader = createHeaderData(filter: filter)
        state.sections = [.sessionItems(header: sectionHeader, items: sectionItems)]
    }
    
    private func createSectionItems(sessionInfos: [UserSessionInfo], filter: OtherUserSessionsFilter) -> [UserSessionListItemViewData] {
        filterSessions(sessionInfos: sessionInfos, by: filter)
            .map {
                UserSessionListItemViewDataFactory().create(from: $0,
                                                            highlightSessionDetails: filter == .unverified && $0.isCurrent)
            }
    }
    
    private func filterSessions(sessionInfos: [UserSessionInfo], by filter: OtherUserSessionsFilter) -> [UserSessionInfo] {
        switch filter {
        case .all:
            return sessionInfos.filter { !$0.isCurrent }
        case .inactive:
            return sessionInfos.filter { !$0.isActive }
        case .unverified:
            return sessionInfos.filter { !$0.isVerified }
        }
    }
    
    private func createHeaderData(filter: OtherUserSessionsFilter) -> UserOtherSessionsHeaderViewData {
        switch filter {
        case .all:
            return UserOtherSessionsHeaderViewData(title: nil,
                                                   subtitle: VectorL10n.userSessionsOverviewOtherSessionsSectionInfo,
                                                   iconName: nil)
        case .inactive:
            return UserOtherSessionsHeaderViewData(title: VectorL10n.userSessionsOverviewSecurityRecommendationsInactiveTitle,
                                                   subtitle: VectorL10n.userSessionsOverviewSecurityRecommendationsInactiveInfo,
                                                   iconName: Asset.Images.userOtherSessionsInactive.name)
        case .unverified:
            return UserOtherSessionsHeaderViewData(title: VectorL10n.userSessionsOverviewSecurityRecommendationsUnverifiedTitle,
                                                   subtitle: VectorL10n.userOtherSessionUnverifiedSessionsHeaderSubtitle,
                                                   iconName: Asset.Images.userOtherSessionsUnverified.name)
        }
    }
}
