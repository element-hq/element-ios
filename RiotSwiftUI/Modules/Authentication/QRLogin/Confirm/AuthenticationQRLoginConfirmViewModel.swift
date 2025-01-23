//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

typealias AuthenticationQRLoginConfirmViewModelType = StateStoreViewModel<AuthenticationQRLoginConfirmViewState, AuthenticationQRLoginConfirmViewAction>

class AuthenticationQRLoginConfirmViewModel: AuthenticationQRLoginConfirmViewModelType, AuthenticationQRLoginConfirmViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    private let qrLoginService: QRLoginServiceProtocol

    // MARK: Public

    var callback: ((AuthenticationQRLoginConfirmViewModelResult) -> Void)?

    // MARK: - Setup

    init(qrLoginService: QRLoginServiceProtocol) {
        self.qrLoginService = qrLoginService
        super.init(initialViewState: AuthenticationQRLoginConfirmViewState())

        switch qrLoginService.state {
        case .waitingForConfirmation(let code):
            state.confirmationCode = code
        default:
            break
        }
    }

    // MARK: - Public

    override func process(viewAction: AuthenticationQRLoginConfirmViewAction) {
        switch viewAction {
        case .confirm:
            callback?(.confirm)
        case .cancel:
            callback?(.cancel)
        }
    }
}
