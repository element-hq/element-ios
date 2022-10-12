//
// Copyright 2022 New Vector Ltd
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
import Foundation
import SwiftUI

class MockQRLoginService: QRLoginServiceProtocol {
    private let mockCanDisplayQR: Bool

    init(withState state: QRLoginServiceState = .initial,
         mode: QRLoginServiceMode = .notAuthenticated,
         canDisplayQR: Bool = true) {
        self.state = state
        self.mode = mode
        mockCanDisplayQR = canDisplayQR
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
