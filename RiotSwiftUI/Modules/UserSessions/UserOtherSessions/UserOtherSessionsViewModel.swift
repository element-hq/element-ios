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
    
    init(sessions: [UserSessionInfo],
         filter: OtherUserSessionsFilter,
         title: String) {
        
        super.init(initialViewState: UserOtherSessionsViewState(title: title, sections: []))
        updateViewState(sessions: sessions, filter: filter)
    }
    
    // MARK: - Public
    
    override func process(viewAction: UserOtherSessionsViewAction) {
        //        switch viewAction {
        //        case .accept:
        //            completion?(.accept)
        //        case .cancel:
        //            completion?(.cancel)
        //        case .incrementCount:
        //            state.count += 1
        //        case .decrementCount:
        //            state.count -= 1
        //        }
    }
    
    // MARK: - Private
    
    private func updateViewState(sessions: [UserSessionInfo], filter: OtherUserSessionsFilter) {
        let sectionItems = filterSessions(sessions: sessions, by: filter).asViewData()
        let sectionHeader = createHeaderData(filter: filter)
        state.sections = [.sessionItems(header: sectionHeader, items: sectionItems)]
    }
    
    private func filterSessions(sessions: [UserSessionInfo], by filter: OtherUserSessionsFilter) -> [UserSessionInfo] {
        switch filter {
        case .all:
            return sessions.filter { !$0.isCurrent }
        case .inactive:
            return sessions.filter { !$0.isActive }
        case .unverified:
            return sessions.filter { !$0.isVerified }
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
            return UserOtherSessionsHeaderViewData(title: "Inactive sessions",
                                                   subtitle: "Consider signing out from old sessions (90 days or older) you don’t use anymore. Learn more",
                                                   iconName: Asset.Images.userOtherSessionsInactive.name)
        case .unverified:
            // TODO:
            return UserOtherSessionsHeaderViewData(title: nil,
                                                   subtitle: "",
                                                   iconName: nil)
            
        }
    }
}

