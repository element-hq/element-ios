//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias AuthenticationQRLoginScanViewModelType = StateStoreViewModel<AuthenticationQRLoginScanViewState, AuthenticationQRLoginScanViewAction>

class AuthenticationQRLoginScanViewModel: AuthenticationQRLoginScanViewModelType, AuthenticationQRLoginScanViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    private let qrLoginService: QRLoginServiceProtocol

    // MARK: Public

    var callback: ((AuthenticationQRLoginScanViewModelResult) -> Void)?

    // MARK: - Setup

    init(qrLoginService: QRLoginServiceProtocol) {
        self.qrLoginService = qrLoginService
        super.init(initialViewState: .init(canShowDisplayQRButton: qrLoginService.canDisplayQR(),
                                           serviceState: .initial))

        qrLoginService.callbacks.sink { callback in
            switch callback {
            case .didUpdateState:
                self.processServiceState(qrLoginService.state)
            case .didScanQR(let data):
                self.callback?(.qrScanned(data))
            }
        }
        .store(in: &cancellables)

        processServiceState(qrLoginService.state)
        qrLoginService.startScanning()
    }

    // MARK: - Public

    override func process(viewAction: AuthenticationQRLoginScanViewAction) {
        switch viewAction {
        case .goToSettings:
            callback?(.goToSettings)
        case .displayQR:
            callback?(.displayQR)
        }
    }

    // MARK: - Private

    private func processServiceState(_ state: QRLoginServiceState) {
        switch state {
        case .scanningQR:
            self.state.scannerView = qrLoginService.scannerView()
        default:
            break
        }
        self.state.serviceState = state
    }
}
