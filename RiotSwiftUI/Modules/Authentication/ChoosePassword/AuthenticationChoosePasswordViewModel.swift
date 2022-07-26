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

typealias AuthenticationChoosePasswordViewModelType = StateStoreViewModel<AuthenticationChoosePasswordViewState,
                                                                       Never,
                                                                       AuthenticationChoosePasswordViewAction>
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
