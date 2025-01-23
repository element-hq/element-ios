//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

typealias AuthenticationChoosePasswordViewModelType = StateStoreViewModel<AuthenticationChoosePasswordViewState, AuthenticationChoosePasswordViewAction>

class AuthenticationChoosePasswordViewModel: AuthenticationChoosePasswordViewModelType, AuthenticationChoosePasswordViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var callback: (@MainActor (AuthenticationChoosePasswordViewModelResult) -> Void)?

    // MARK: - Setup

    init(password: String = "", signoutAllDevices: Bool = false) {
        let viewState = AuthenticationChoosePasswordViewState(bindings: AuthenticationChoosePasswordBindings(password: password, signoutAllDevices: signoutAllDevices))
        super.init(initialViewState: viewState)
    }

    // MARK: - Public
    
    override func process(viewAction: AuthenticationChoosePasswordViewAction) {
        switch viewAction {
        case .submit:
            Task { await callback?(.submit(state.bindings.password, state.bindings.signoutAllDevices)) }
        case .toggleSignoutAllDevices:
            state.bindings.signoutAllDevices.toggle()
        case .cancel:
            Task { await callback?(.cancel) }
        }
    }

    @MainActor func displayError(_ type: AuthenticationChoosePasswordErrorType) {
        switch type {
        case .mxError(let message):
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: VectorL10n.error,
                                                 message: message)
        case .emailNotVerified:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: VectorL10n.authenticationChoosePasswordNotVerifiedTitle,
                                                 message: VectorL10n.authenticationChoosePasswordNotVerifiedMessage)
        case .unknown:
            state.bindings.alertInfo = AlertInfo(id: type)
        }
    }
}
