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

typealias AuthenticationTermsViewModelType = StateStoreViewModel<AuthenticationTermsViewState, AuthenticationTermsViewAction>

class AuthenticationTermsViewModel: AuthenticationTermsViewModelType, AuthenticationTermsViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var callback: (@MainActor (AuthenticationTermsViewModelResult) -> Void)?

    // MARK: - Setup

    init(homeserver: AuthenticationHomeserverViewData, policies: [AuthenticationTermsPolicy]) {
        super.init(initialViewState: AuthenticationTermsViewState(homeserver: homeserver,
                                                                  bindings: AuthenticationTermsBindings(policies: policies)))
    }

    // MARK: - Public

    override func process(viewAction: AuthenticationTermsViewAction) {
        switch viewAction {
        case .next:
            Task { await callback?(.next) }
        case .showPolicy(let policy):
            Task { await callback?(.showPolicy(policy)) }
        case .cancel:
            Task { await callback?(.cancel) }
        }
    }
    
    @MainActor func displayError(_ type: AuthenticationTermsErrorType) {
        switch type {
        case .mxError(let message):
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: VectorL10n.error,
                                                 message: message)
        case .invalidPolicyURL:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: VectorL10n.error,
                                                 message: VectorL10n.authenticationTermsPolicyUrlError)
        case .unknown:
            state.bindings.alertInfo = AlertInfo(id: type)
        }
    }
}
