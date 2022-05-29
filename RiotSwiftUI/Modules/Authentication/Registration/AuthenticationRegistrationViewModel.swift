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
import Combine

typealias AuthenticationRegistrationViewModelType = StateStoreViewModel<AuthenticationRegistrationViewState,
                                                                        Never,
                                                                        AuthenticationRegistrationViewAction>

class AuthenticationRegistrationViewModel: AuthenticationRegistrationViewModelType, AuthenticationRegistrationViewModelProtocol {

    // MARK: - Properties

    // MARK: Public

    @MainActor var callback: ((AuthenticationRegistrationViewModelResult) -> Void)?

    // MARK: - Setup

    init(homeserverAddress: String, showRegistrationForm: Bool = true, ssoIdentityProviders: [SSOIdentityProvider]) {
        let bindings = AuthenticationRegistrationBindings()
        let viewState = AuthenticationRegistrationViewState(homeserverAddress: HomeserverAddress.displayable(homeserverAddress),
                                                            showRegistrationForm: showRegistrationForm,
                                                            ssoIdentityProviders: ssoIdentityProviders,
                                                            bindings: bindings)
        
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
        case .clearUsernameError:
            Task { await clearUsernameError() }
        case .next:
            Task { await callback?(.createAccount(username: state.bindings.username, password: state.bindings.password)) }
        case .continueWithSSO(let id):
            break
        }
    }
    
    @MainActor func update(homeserverAddress: String, showRegistrationForm: Bool, ssoIdentityProviders: [SSOIdentityProvider]) {
        state.homeserverAddress = HomeserverAddress.displayable(homeserverAddress)
        state.showRegistrationForm = showRegistrationForm
        state.ssoIdentityProviders = ssoIdentityProviders
    }
    
    @MainActor func displayError(_ type: AuthenticationRegistrationErrorType) {
        switch type {
        case .usernameUnavailable(let message):
            state.usernameErrorMessage = message
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
    
    /// Clear any errors being shown in the username text field footer.
    @MainActor private func clearUsernameError() {
        guard state.usernameErrorMessage != nil else { return }
        state.usernameErrorMessage = nil
    }
}
