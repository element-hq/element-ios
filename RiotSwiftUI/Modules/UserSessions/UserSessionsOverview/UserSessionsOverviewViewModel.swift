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
        
        let viewState = UserSessionsOverviewViewState()
        
        super.init(initialViewState: viewState)
    }
    
    // MARK: - Public

    override func process(viewAction: UserSessionsOverviewViewAction) {
        switch viewAction {
        case .verifyCurrentSession:
            break
        case .viewCurrentSessionDetails:
            break
        case .viewAllUnverifiedSessions:
            break
        case .viewAllInactiveSessions:
            break
        case .viewAllOtherSessions:
            break
        }
    }
}
