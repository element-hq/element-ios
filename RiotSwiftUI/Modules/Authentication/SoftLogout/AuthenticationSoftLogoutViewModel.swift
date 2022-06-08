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

typealias AuthenticationSoftLogoutViewModelType = StateStoreViewModel<AuthenticationSoftLogoutViewState,
                                                                       Never,
                                                                       AuthenticationSoftLogoutViewAction>
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
