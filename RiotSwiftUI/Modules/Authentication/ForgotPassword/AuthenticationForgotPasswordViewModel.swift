//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

typealias AuthenticationForgotPasswordViewModelType = StateStoreViewModel<AuthenticationForgotPasswordViewState, AuthenticationForgotPasswordViewAction>

class AuthenticationForgotPasswordViewModel: AuthenticationForgotPasswordViewModelType, AuthenticationForgotPasswordViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var callback: (@MainActor (AuthenticationForgotPasswordViewModelResult) -> Void)?

    // MARK: - Setup

    init(homeserver: AuthenticationHomeserverViewData, emailAddress: String = "") {
        let viewState = AuthenticationForgotPasswordViewState(homeserver: homeserver,
                                                              bindings: AuthenticationForgotPasswordBindings(emailAddress: emailAddress))
        super.init(initialViewState: viewState)
    }

    // MARK: - Public
    
    override func process(viewAction: AuthenticationForgotPasswordViewAction) {
        switch viewAction {
        case .send:
            Task { await callback?(.send(state.bindings.emailAddress)) }
        case .resend:
            Task { await callback?(.send(state.bindings.emailAddress)) }
        case .done:
            Task { await callback?(.done) }
        case .cancel:
            Task { await callback?(.cancel) }
        case .goBack:
            Task { await callback?(.goBack) }
        }
    }
    
    @MainActor func updateForSentEmail() {
        state.hasSentEmail = true
    }

    @MainActor func goBackToEnterEmailForm() {
        state.hasSentEmail = false
    }
    
    @MainActor func displayError(_ type: AuthenticationForgotPasswordErrorType) {
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
