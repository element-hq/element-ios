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

// MARK: - QRLoginServiceMode

enum QRLoginServiceMode {
    case authenticated
    case notAuthenticated
}

// MARK: - QRLoginServiceError

enum QRLoginServiceError: Error, Equatable {
    case noCameraAccess
    case noCameraAvailable
    case invalidQR
    case requestDenied
    case requestTimedOut
    case rendezvousFailed
}

// MARK: - QRLoginServiceState

enum QRLoginServiceState: Equatable {
    case initial
    case scanningQR
    case connectingToDevice
    case waitingForConfirmation(_ code: String)
    case waitingForRemoteSignIn
    case failed(error: QRLoginServiceError)
    // This is really an MXSession but that would break RiotSwiftUI
    case completed(session: Any, securityCompleted: Bool)

    static func == (lhs: QRLoginServiceState, rhs: QRLoginServiceState) -> Bool {
        switch (lhs, rhs) {
        case (.initial, .initial):
            return true
        case (.scanningQR, .scanningQR):
            return true
        case (.connectingToDevice, .connectingToDevice):
            return true
        case (let .waitingForConfirmation(code1), let .waitingForConfirmation(code2)):
            return code1 == code2
        case (.waitingForRemoteSignIn, .waitingForRemoteSignIn):
            return true
        case (let .failed(error1), let .failed(error2)):
            return error1 == error2
        case (.completed, .completed):
            return true
        default:
            return false
        }
    }
}

// MARK: - QRLoginServiceCallback

enum QRLoginServiceCallback {
    case didScanQR(Data)
    case didUpdateState
}

// MARK: - QRLoginServiceProtocol

protocol QRLoginServiceProtocol {
    var mode: QRLoginServiceMode { get }
    var state: QRLoginServiceState { get }
    var callbacks: PassthroughSubject<QRLoginServiceCallback, Never> { get }
    func isServiceAvailable() async throws -> Bool
    func canDisplayQR() -> Bool
    func generateQRCode() async throws -> QRLoginCode

    // MARK: QR Scanner

    func scannerView() -> AnyView
    func startScanning()
    func stopScanning(destroy: Bool)
    func processScannedQR(_ data: Data)

    func confirmCode()
    func restart()
    func reset()
}
