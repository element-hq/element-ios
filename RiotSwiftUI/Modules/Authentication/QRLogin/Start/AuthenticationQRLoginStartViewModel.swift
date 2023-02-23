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
