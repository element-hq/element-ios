//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

typealias AuthenticationQRLoginFailureViewModelType = StateStoreViewModel<AuthenticationQRLoginFailureViewState, AuthenticationQRLoginFailureViewAction>

class AuthenticationQRLoginFailureViewModel: AuthenticationQRLoginFailureViewModelType, AuthenticationQRLoginFailureViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    private let qrLoginService: QRLoginServiceProtocol

    // MARK: Public

    var callback: ((AuthenticationQRLoginFailureViewModelResult) -> Void)?

    // MARK: - Setup

    init(qrLoginService: QRLoginServiceProtocol) {
        self.qrLoginService = qrLoginService
        super.init(initialViewState: AuthenticationQRLoginFailureViewState(retryButtonVisible: false))

        updateFailureText(for: qrLoginService.state)
        qrLoginService.callbacks.sink { [weak self] callback in
            guard let self = self else { return }
            switch callback {
            case .didUpdateState:
                self.updateFailureText(for: qrLoginService.state)
            default:
                break
            }
        }
        .store(in: &cancellables)
    }

    private func updateFailureText(for state: QRLoginServiceState) {
        switch state {
        case .failed(let error):
            switch error {
            case .invalidQR:
                self.state.failureText = VectorL10n.authenticationQrLoginFailureInvalidQr
                self.state.retryButtonVisible = true
            case .deviceNotSupported:
                self.state.failureText = VectorL10n.authenticationQrLoginFailureDeviceNotSupported
                self.state.retryButtonVisible = true
            case .requestDenied:
                self.state.failureText = VectorL10n.authenticationQrLoginFailureRequestDenied
                self.state.retryButtonVisible = false
            case .requestTimedOut:
                self.state.failureText = VectorL10n.authenticationQrLoginFailureRequestTimedOut
                self.state.retryButtonVisible = true
            default:
                break
            }
        default:
            break
        }
    }

    // MARK: - Public

    override func process(viewAction: AuthenticationQRLoginFailureViewAction) {
        switch viewAction {
        case .retry:
            callback?(.retry)
        case .cancel:
            callback?(.cancel)
        }
    }
}
