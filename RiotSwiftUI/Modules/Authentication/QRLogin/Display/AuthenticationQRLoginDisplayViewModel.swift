//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

typealias AuthenticationQRLoginDisplayViewModelType = StateStoreViewModel<AuthenticationQRLoginDisplayViewState, AuthenticationQRLoginDisplayViewAction>

class AuthenticationQRLoginDisplayViewModel: AuthenticationQRLoginDisplayViewModelType, AuthenticationQRLoginDisplayViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    private let qrLoginService: QRLoginServiceProtocol

    // MARK: Public

    var callback: ((AuthenticationQRLoginDisplayViewModelResult) -> Void)?

    // MARK: - Setup

    init(qrLoginService: QRLoginServiceProtocol) {
        self.qrLoginService = qrLoginService
        super.init(initialViewState: AuthenticationQRLoginDisplayViewState())

        Task { @MainActor in
            let generator = QRCodeGenerator()
            let qrData = try await qrLoginService.generateQRCode()
            guard let jsonString = qrData.jsonString,
                  let data = jsonString.data(using: .isoLatin1) else {
                return
            }

            do {
                state.qrImage = try generator.generateCode(from: data,
                                                           with: CGSize(width: 240, height: 240),
                                                           offColor: .clear)
            } catch {
                // MXLog.error("[AuthenticationQRLoginDisplayViewModel] failed to generate QR", context: error)
            }
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
