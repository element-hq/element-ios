//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

typealias AuthenticationSoftLogoutViewModelType = StateStoreViewModel<AuthenticationSoftLogoutViewState, AuthenticationSoftLogoutViewAction>

class AuthenticationSoftLogoutViewModel: AuthenticationSoftLogoutViewModelType, AuthenticationSoftLogoutViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var callback: (@MainActor (AuthenticationSoftLogoutViewModelResult) -> Void)?

    // MARK: - Setup

    init(credentials: SoftLogoutCredentials,
         homeserver: AuthenticationHomeserverViewData,
         keyBackupNeeded: Bool,
         password: String = "") {
        let bindings = AuthenticationSoftLogoutBindings(password: password)
        let viewState = AuthenticationSoftLogoutViewState(credentials: credentials,
                                                          homeserver: homeserver,
                                                          keyBackupNeeded: keyBackupNeeded,
                                                          bindings: bindings)
        super.init(initialViewState: viewState)
    }

    // MARK: - Public
    
    override func process(viewAction: AuthenticationSoftLogoutViewAction) {
        switch viewAction {
        case .login:
            Task { await callback?(.login(state.bindings.password)) }
        case .forgotPassword:
            Task { await callback?(.forgotPassword) }
        case .clearAllData:
            Task { await callback?(.clearAllData) }
        case .continueWithSSO(let provider):
            Task { await callback?(.continueWithSSO(provider)) }
        case .fallback:
            Task { await callback?(.fallback) }
        }
    }

    @MainActor func displayError(_ type: AuthenticationSoftLogoutErrorType) {
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
