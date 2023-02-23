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
