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

typealias AuthenticationVerifyEmailViewModelType = StateStoreViewModel<AuthenticationVerifyEmailViewState,
                                                                       Never,
                                                                       AuthenticationVerifyEmailViewAction>
class AuthenticationVerifyEmailViewModel: AuthenticationVerifyEmailViewModelType, AuthenticationVerifyEmailViewModelProtocol {

    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var callback: (@MainActor (AuthenticationVerifyEmailViewModelResult) -> Void)?

    // MARK: - Setup

    init(homeserver: AuthenticationHomeserverViewData, emailAddress: String = "") {
        let viewState = AuthenticationVerifyEmailViewState(homeserver: homeserver,
                                                           bindings: AuthenticationVerifyEmailBindings(emailAddress: emailAddress))
        super.init(initialViewState: viewState)
    }

    // MARK: - Public
    
    override func process(viewAction: AuthenticationVerifyEmailViewAction) {
        switch viewAction {
        case .send:
            Task { await callback?(.send(state.bindings.emailAddress)) }
        case .resend:
            Task { await callback?(.resend) }
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
    
    @MainActor func displayError(_ type: AuthenticationVerifyEmailErrorType) {
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
