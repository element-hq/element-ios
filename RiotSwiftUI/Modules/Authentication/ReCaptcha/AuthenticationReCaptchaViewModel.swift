//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
