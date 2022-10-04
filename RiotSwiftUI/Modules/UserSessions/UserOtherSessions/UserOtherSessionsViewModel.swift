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
    private let sessionsInfo: [UserSessionInfo]
    
    init(sessionsInfo: [UserSessionInfo],
         filter: OtherUserSessionsFilter,
         title: String) {
        self.sessionsInfo = sessionsInfo
        super.init(initialViewState: UserOtherSessionsViewState(title: title, sections: []))
        updateViewState(sessionsInfo: sessionsInfo, filter: filter)
    }
    
    // MARK: - Public
    
    override func process(viewAction: UserOtherSessionsViewAction) {
        switch viewAction {
        case let .userOtherSessionSelected(sessionId: sessionId):
            guard let session = sessionsInfo.first(where: {$0.id == sessionId}) else {
                assertionFailure("Session should exist in the array.")
                return
            }
            completion?(.showUserSessionOverview(sessionInfo: session))
        }
    }
    
    // MARK: - Private
    
    private func updateViewState(sessionsInfo: [UserSessionInfo], filter: OtherUserSessionsFilter) {
        let sectionItems = filterSessions(sessionsInfo: sessionsInfo, by: filter).asViewData()
        let sectionHeader = createHeaderData(filter: filter)
        state.sections = [.sessionItems(header: sectionHeader, items: sectionItems)]
    }
    
    private func filterSessions(sessionsInfo: [UserSessionInfo], by filter: OtherUserSessionsFilter) -> [UserSessionInfo] {
        switch filter {
        case .all:
            return sessionsInfo.filter { !$0.isCurrent }
        case .inactive:
            return sessionsInfo.filter { !$0.isActive }
        case .unverified:
            return sessionsInfo.filter { !$0.isVerified }
        }
    }
    
    private func createHeaderData(filter: OtherUserSessionsFilter) -> UserOtherSessionsHeaderViewData {
        switch filter {
        case .all:
            // TODO:
            return UserOtherSessionsHeaderViewData(title: nil,
                                                   subtitle: "",
                                                   iconName: nil)
        case .inactive:
            return UserOtherSessionsHeaderViewData(title: VectorL10n.userSessionsOverviewSecurityRecommendationsInactiveTitle,
                                                   subtitle: VectorL10n.userSessionsOverviewSecurityRecommendationsInactiveInfo,
                                                   iconName: Asset.Images.userOtherSessionsInactive.name)
        case .unverified:
            // TODO:
            return UserOtherSessionsHeaderViewData(title: nil,
                                                   subtitle: "",
                                                   iconName: nil)
        }
    }
}

