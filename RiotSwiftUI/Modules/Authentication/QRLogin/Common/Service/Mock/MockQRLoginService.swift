//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import SwiftUI

class MockQRLoginService: QRLoginServiceProtocol {
    private let mockCanDisplayQR: Bool
    private let mockFlow: String?

    init(withState state: QRLoginServiceState = .initial,
         mode: QRLoginServiceMode = .notAuthenticated,
         canDisplayQR: Bool = true,
         flow: String? = nil) {
        self.state = state
        self.mode = mode
        mockCanDisplayQR = canDisplayQR
        mockFlow = flow
    }

    // MARK: - QRLoginServiceProtocol

    let mode: QRLoginServiceMode

    var state: QRLoginServiceState {
        didSet {
            if state != oldValue {
                callbacks.send(.didUpdateState)
            }
        }
    }

    let callbacks = PassthroughSubject<QRLoginServiceCallback, Never>()
    
    func isServiceAvailable() async throws -> Bool {
        true
    }

    func canDisplayQR() -> Bool {
        mockCanDisplayQR
    }

    func generateQRCode() async throws -> QRLoginCode {
        let details = RendezvousDetails(algorithm: "m.rendezvous.v1.curve25519-aes-sha256",
                                        transport: .init(type: "http.v1",
                                                         uri: "https://matrix.org"),
                                        key: "some.public.key")
        return QRLoginCode(rendezvous: details,
                           flow: mockFlow,
                           intent: "login.start")
    }

    func scannerView() -> AnyView {
        AnyView(Color.red)
    }

    func startScanning() { }

    func stopScanning(destroy: Bool) { }

    func processScannedQR(_ data: Data) {
        state = .connectingToDevice
        state = .waitingForConfirmation("28E-1B9-D0F-896")
    }

    func confirmCode() {
        state = .waitingForRemoteSignIn
    }

    func restart() {
        state = .initial
    }

    func reset() {
        state = .initial
    }
}
