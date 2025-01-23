//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
