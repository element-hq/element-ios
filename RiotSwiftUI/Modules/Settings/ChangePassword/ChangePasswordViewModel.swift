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

typealias ChangePasswordViewModelType = StateStoreViewModel<ChangePasswordViewState, ChangePasswordViewAction>

class ChangePasswordViewModel: ChangePasswordViewModelType, ChangePasswordViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var callback: (@MainActor (ChangePasswordViewModelResult) -> Void)?

    // MARK: - Setup

    init(oldPassword: String = "",
         newPassword1: String = "",
         newPassword2: String = "",
         passwordRequirements: String = "",
         signoutAllDevices: Bool = false) {
        let bindings = ChangePasswordBindings(oldPassword: oldPassword,
                                              newPassword1: newPassword1,
                                              newPassword2: newPassword2,
                                              signoutAllDevices: signoutAllDevices)
        let viewState = ChangePasswordViewState(passwordRequirements: passwordRequirements,
                                                bindings: bindings)
        super.init(initialViewState: viewState)
    }

    // MARK: - Public
    
    override func process(viewAction: ChangePasswordViewAction) {
        switch viewAction {
        case .submit:
            guard state.bindings.newPassword1 == state.bindings.newPassword2 else {
                Task { await displayError(.passwordsDontMatch) }
                return
            }
            Task { await callback?(.submit(oldPassword: state.bindings.oldPassword,
                                           newPassword: state.bindings.newPassword1,
                                           signoutAllDevices: state.bindings.signoutAllDevices)) }
        case .toggleSignoutAllDevices:
            state.bindings.signoutAllDevices.toggle()
        }
    }

    @MainActor func displayError(_ type: ChangePasswordErrorType) {
        switch type {
        case .mxError(let message):
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: VectorL10n.error,
                                                 message: message)
        case .passwordsDontMatch:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: VectorL10n.error,
                                                 message: VectorL10n.authPasswordDontMatch)
        case .unknown:
            state.bindings.alertInfo = AlertInfo(id: type)
        }
    }
}
