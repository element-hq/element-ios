//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

typealias AuthenticationQRLoginStartViewModelType = StateStoreViewModel<AuthenticationQRLoginStartViewState, AuthenticationQRLoginStartViewAction>

class AuthenticationQRLoginStartViewModel: AuthenticationQRLoginStartViewModelType, AuthenticationQRLoginStartViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    private let qrLoginService: QRLoginServiceProtocol

    // MARK: Public

    var callback: ((AuthenticationQRLoginStartViewModelResult) -> Void)?

    // MARK: - Setup

    init(qrLoginService: QRLoginServiceProtocol) {
        self.qrLoginService = qrLoginService
        super.init(initialViewState: AuthenticationQRLoginStartViewState(canShowDisplayQRButton: qrLoginService.canDisplayQR()))
    }

    // MARK: - Public

    override func process(viewAction: AuthenticationQRLoginStartViewAction) {
        switch viewAction {
        case .scanQR:
            callback?(.scanQR)
        case .displayQR:
            callback?(.displayQR)
        }
    }
}
