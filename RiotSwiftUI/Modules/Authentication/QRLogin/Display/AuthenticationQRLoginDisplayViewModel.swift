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

typealias AuthenticationQRLoginDisplayViewModelType = StateStoreViewModel<AuthenticationQRLoginDisplayViewState, AuthenticationQRLoginDisplayViewAction>

class AuthenticationQRLoginDisplayViewModel: AuthenticationQRLoginDisplayViewModelType, AuthenticationQRLoginDisplayViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var callback: ((AuthenticationQRLoginDisplayViewModelResult) -> Void)?

    // MARK: - Setup

    init() {
        super.init(initialViewState: AuthenticationQRLoginDisplayViewState())

        let generator = QRCodeGenerator()
        let qrData = [
            "key_1": "value_1",
            "key_2": "value_2",
        ]
        guard let jsonString = qrData.jsonString,
              let data = jsonString.data(using: .isoLatin1) else {
            return
        }

        do {
            self.state.qrImage = try generator.generateCode(from: data,
                                                            with: CGSize(width: 240, height: 240),
                                                            offColor: .clear)
        } catch {
            //MXLog.error("[AuthenticationQRLoginDisplayViewModel] failed to generate QR", context: error)
        }
    }

    // MARK: - Public

    override func process(viewAction: AuthenticationQRLoginDisplayViewAction) {
        switch viewAction {
        case .cancel:
            callback?(.cancel)
        }
    }
}
