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
