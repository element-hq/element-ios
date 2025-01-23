//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
