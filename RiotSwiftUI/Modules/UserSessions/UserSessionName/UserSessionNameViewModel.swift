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

typealias UserSessionNameViewModelType = StateStoreViewModel<UserSessionNameViewState, UserSessionNameViewAction>

class UserSessionNameViewModel: UserSessionNameViewModelType, UserSessionNameViewModelProtocol {
    var completion: ((UserSessionNameViewModelResult) -> Void)?

    init(sessionInfo: UserSessionInfo) {
        super.init(initialViewState: UserSessionNameViewState(bindings: .init(sessionName: sessionInfo.name ?? ""),
                                                              currentName: sessionInfo.name ?? ""))
    }

    // MARK: - Public

    override func process(viewAction: UserSessionNameViewAction) {
        switch viewAction {
        case .done:
            completion?(.updateName(state.bindings.sessionName))
        case .cancel:
            completion?(.cancel)
        case .learnMore:
            completion?(.learnMore)
        }
    }
    
    func processError(_ error: NSError?) {
        state.bindings.alertInfo = AlertInfo(error: error)
    }
}
