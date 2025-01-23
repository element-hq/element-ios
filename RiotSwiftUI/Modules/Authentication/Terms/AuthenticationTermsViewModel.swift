//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
