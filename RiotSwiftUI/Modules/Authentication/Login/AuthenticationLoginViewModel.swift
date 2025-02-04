//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

typealias AuthenticationLoginViewModelType = StateStoreViewModel<AuthenticationLoginViewState, AuthenticationLoginViewAction>

class AuthenticationLoginViewModel: AuthenticationLoginViewModelType, AuthenticationLoginViewModelProtocol {
    // MARK: - Properties

    // MARK: Public

    var callback: (@MainActor (AuthenticationLoginViewModelResult) -> Void)?

    // MARK: - Setup

    init(homeserver: AuthenticationHomeserverViewData) {
        let bindings = AuthenticationLoginBindings()
        let viewState = AuthenticationLoginViewState(homeserver: homeserver, bindings: bindings)
        
        super.init(initialViewState: viewState)
    }
    
    // MARK: - Public

    override func process(viewAction: AuthenticationLoginViewAction) {
        switch viewAction {
        case .selectServer:
            Task { await callback?(.selectServer) }
        case .parseUsername:
            Task { await callback?(.parseUsername(state.bindings.username)) }
        case .forgotPassword:
            Task { await callback?(.forgotPassword) }
        case .next:
            Task { await callback?(.login(username: state.bindings.username, password: state.bindings.password)) }
        case .fallback:
            Task { await callback?(.fallback) }
        case .continueWithSSO(let provider):
            Task { await callback?(.continueWithSSO(provider)) }
        case .qrLogin:
            Task { await callback?(.qrLogin) }
        }
    }
    
    @MainActor func update(isLoading: Bool) {
        guard state.isLoading != isLoading else { return }
        state.isLoading = isLoading
    }
    
    @MainActor func update(homeserver: AuthenticationHomeserverViewData) {
        state.homeserver = homeserver
    }
    
    @MainActor func displayError(_ type: AuthenticationLoginErrorType) {
        switch type {
        case .mxError(let message):
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: VectorL10n.error,
                                                 message: message)
        case .invalidHomeserver:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: VectorL10n.error,
                                                 message: VectorL10n.authenticationServerSelectionGenericError)
        case .unknown:
            state.bindings.alertInfo = AlertInfo(id: type)
        }
    }
}
