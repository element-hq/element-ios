//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias AuthenticationRegistrationViewModelType = StateStoreViewModel<AuthenticationRegistrationViewState, AuthenticationRegistrationViewAction>

class AuthenticationRegistrationViewModel: AuthenticationRegistrationViewModelType, AuthenticationRegistrationViewModelProtocol {
    // MARK: - Properties

    // MARK: Public

    var callback: (@MainActor (AuthenticationRegistrationViewModelResult) -> Void)?

    // MARK: - Setup

    init(homeserver: AuthenticationHomeserverViewData, showReplacementAppBanner: Bool) {
        let bindings = AuthenticationRegistrationBindings()
        let viewState = AuthenticationRegistrationViewState(homeserver: homeserver, showReplacementAppBanner: showReplacementAppBanner, bindings: bindings)
        
        super.init(initialViewState: viewState)
    }
    
    // MARK: - Public

    override func process(viewAction: AuthenticationRegistrationViewAction) {
        switch viewAction {
        case .selectServer:
            Task { await callback?(.selectServer) }
        case .validateUsername:
            Task { await validateUsername() }
        case .enablePasswordValidation:
            Task { await enablePasswordValidation() }
        case .resetUsernameAvailability:
            Task { await resetUsernameAvailability() }
        case .next:
            Task { await callback?(.createAccount(username: state.bindings.username, password: state.bindings.password)) }
        case .continueWithSSO(let provider):
            Task { await callback?(.continueWithSSO(provider)) }
        case .fallback:
            Task { await callback?(.fallback) }
        case .downloadReplacementApp(let replacementApp):
            Task { await callback?(.downloadReplacementApp(replacementApp)) }
        }
    }
    
    @MainActor func update(isLoading: Bool) {
        guard state.isLoading != isLoading else { return }
        state.isLoading = isLoading
    }
    
    @MainActor func update(homeserver: AuthenticationHomeserverViewData) {
        state.homeserver = homeserver
        
        // Only the initial homeserver will ever need this, it isn't possible to update the
        // server to another one that requires the replacement app as the selection will fail.
        state.showReplacementAppBanner = false
    }
    
    @MainActor func update(username: String) {
        guard username != state.bindings.username else { return }
        state.bindings.username = username
    }
    
    @MainActor func confirmUsernameAvailability(_ username: String) {
        guard username == state.bindings.username else { return }
        state.usernameAvailability = .available
    }
    
    @MainActor func displayError(_ type: AuthenticationRegistrationErrorType) {
        switch type {
        case .usernameUnavailable(let message):
            state.usernameAvailability = .invalid(message)
        case .mxError(let message):
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: VectorL10n.error,
                                                 message: message)
        case .invalidHomeserver, .invalidResponse:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: VectorL10n.error,
                                                 message: VectorL10n.authenticationServerSelectionGenericError)
        case .registrationDisabled:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: VectorL10n.error,
                                                 message: VectorL10n.loginErrorRegistrationIsNotSupported)
        case .registrationNotSupported:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: VectorL10n.error,
                                                 message: VectorL10n.sunsetDelegatedOidcRegistrationNotSupportedGenericError)
        case .unknown:
            state.bindings.alertInfo = AlertInfo(id: type)
        }
    }
    
    // MARK: - Private
    
    /// Validate the supplied username with the homeserver.
    @MainActor private func validateUsername() {
        if !state.hasEditedUsername {
            state.hasEditedUsername = true
        }
        
        callback?(.validateUsername(state.bindings.username))
    }
    
    /// Allows password validation to take place.
    @MainActor private func enablePasswordValidation() {
        guard !state.hasEditedPassword else { return }
        state.hasEditedPassword = true
    }
    
    /// Reset the username's availability, clearing any messages being shown in the username text field footer.
    @MainActor private func resetUsernameAvailability() {
        if case .unknown = state.usernameAvailability { return }
        state.usernameAvailability = .unknown
    }
}
