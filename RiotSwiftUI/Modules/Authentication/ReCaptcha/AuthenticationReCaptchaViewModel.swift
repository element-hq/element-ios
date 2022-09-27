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

typealias AuthenticationReCaptchaViewModelType = StateStoreViewModel<AuthenticationReCaptchaViewState, AuthenticationReCaptchaViewAction>

class AuthenticationReCaptchaViewModel: AuthenticationReCaptchaViewModelType, AuthenticationReCaptchaViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var callback: (@MainActor (AuthenticationReCaptchaViewModelResult) -> Void)?

    // MARK: - Setup

    init(siteKey: String, homeserverURL: URL) {
        super.init(initialViewState: AuthenticationReCaptchaViewState(siteKey: siteKey,
                                                                      homeserverURL: homeserverURL))
    }

    // MARK: - Public

    override func process(viewAction: AuthenticationReCaptchaViewAction) {
        switch viewAction {
        case .cancel:
            Task { await callback?(.cancel) }
        case .validate(let response):
            Task { await callback?(.validate(response)) }
        }
    }
    
    @MainActor func displayError(_ type: AuthenticationReCaptchaErrorType) {
        switch type {
        case .mxError(let message):
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: VectorL10n.error,
                                                 message: message)
        case .unknown:
            state.bindings.alertInfo = AlertInfo(id: type)
        }
    }
}
