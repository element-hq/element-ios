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

typealias UserSessionOverviewViewModelType = StateStoreViewModel<UserSessionOverviewViewState, Never, UserSessionOverviewViewAction>

class UserSessionOverviewViewModel: UserSessionOverviewViewModelType, UserSessionOverviewViewModelProtocol {
    private let userSessionInfo: UserSessionInfo
    
    var completion: ((UserSessionOverviewViewModelResult) -> Void)?
    
    init(userSessionInfo: UserSessionInfo, isCurrentSession: Bool) {
        self.userSessionInfo = userSessionInfo
        
        let cardViewData = UserSessionCardViewData(userSessionInfo: userSessionInfo, isCurrentSessionDisplayMode: isCurrentSession)
        let state = UserSessionOverviewViewState(cardViewData: cardViewData, isCurrentSession: isCurrentSession)
        super.init(initialViewState: state)
    }
    
    // MARK: - Public
    
    override func process(viewAction: UserSessionOverviewViewAction) {
        switch viewAction {
        case .verifyCurrentSession:
            completion?(.verifyCurrentSession)
        case .viewSessionDetails:
            completion?(.showSessionDetails(sessionInfo: userSessionInfo))
        }
    }
}
