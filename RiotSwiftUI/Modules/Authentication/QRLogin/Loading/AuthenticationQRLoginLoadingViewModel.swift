//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

typealias AuthenticationQRLoginLoadingViewModelType = StateStoreViewModel<AuthenticationQRLoginLoadingViewState, AuthenticationQRLoginLoadingViewAction>

class AuthenticationQRLoginLoadingViewModel: AuthenticationQRLoginLoadingViewModelType, AuthenticationQRLoginLoadingViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    private let qrLoginService: QRLoginServiceProtocol

    // MARK: Public

    var callback: ((AuthenticationQRLoginLoadingViewModelResult) -> Void)?

    // MARK: - Setup

    init(qrLoginService: QRLoginServiceProtocol) {
        self.qrLoginService = qrLoginService
        super.init(initialViewState: AuthenticationQRLoginLoadingViewState())

        updateLoadingText(for: qrLoginService.state)
        qrLoginService.callbacks.sink { [weak self] callback in
            guard let self = self else { return }
            switch callback {
            case .didUpdateState:
                self.updateLoadingText(for: qrLoginService.state)
            default:
                break
            }
        }
        .store(in: &cancellables)
    }

    private func updateLoadingText(for state: QRLoginServiceState) {
        switch state {
        case .connectingToDevice:
            self.state.loadingText = VectorL10n.authenticationQrLoginLoadingConnectingDevice
        case .waitingForRemoteSignIn:
            self.state.loadingText = VectorL10n.authenticationQrLoginLoadingWaitingSignin
        case .completed:
            self.state.loadingText = VectorL10n.authenticationQrLoginLoadingSignedIn
        default:
            break
        }
    }

    // MARK: - Public

    override func process(viewAction: AuthenticationQRLoginLoadingViewAction) {
        switch viewAction {
        case .cancel:
            callback?(.cancel)
        }
    }
}
