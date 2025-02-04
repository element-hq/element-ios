//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    case deviceNotSupported
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
