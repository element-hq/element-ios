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
    var state: QRLoginServiceState = .initial {
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

    func generateQRCode() async throws -> QRLoginCode {
        let transport = QRLoginRendezvousTransportDetails(type: "http.v1",
                                                          uri: "https://matrix.org")
        let rendezvous = QRLoginRendezvous(transport: transport,
                                           algorithm: "m.rendezvous.v1.curve25519-aes-sha256",
                                           key: "")
        return QRLoginCode(user: "@mock:matrix.org",
                           initiator: .new,
                           rendezvous: rendezvous)
    }

    func scannerView() -> AnyView {
        AnyView(Color.blue)
    }

    func startScanning() {
        state = .scanningQR
    }

    func stopScanning(destroy: Bool) { }

    func processScannedQR(_ data: Data) {
        state = .processingQR
        state = .waitingForRemoteSignIn
    }
}
