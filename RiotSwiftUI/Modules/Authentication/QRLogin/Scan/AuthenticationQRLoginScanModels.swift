//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

// MARK: - Coordinator

// MARK: View model

enum AuthenticationQRLoginScanViewModelResult: Equatable {
    case goToSettings
    case displayQR
    case qrScanned(Data)

    static func == (lhs: AuthenticationQRLoginScanViewModelResult, rhs: AuthenticationQRLoginScanViewModelResult) -> Bool {
        switch (lhs, rhs) {
        case (.goToSettings, .goToSettings):
            return true
        case (.displayQR, .displayQR):
            return true
        case (let .qrScanned(data1), let .qrScanned(data2)):
            return data1 == data2
        default:
            return false
        }
    }
}

// MARK: View

struct AuthenticationQRLoginScanViewState: BindableState {
    var canShowDisplayQRButton: Bool
    var serviceState: QRLoginServiceState
    var scannerView: AnyView?
}

enum AuthenticationQRLoginScanViewAction {
    case goToSettings
    case displayQR
}
