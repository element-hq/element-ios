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
