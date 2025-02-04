//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

/// Using an enum for the screen allows you define the different state cases with
/// the relevant associated data for each case.
enum MockAuthenticationQRLoginScanScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case scanning
    case noCameraAvailable
    case noCameraAccess
    case noCameraAvailableNoDisplayQR
    case noCameraAccessNoDisplayQR
    
    /// The associated screen
    var screenType: Any.Type {
        AuthenticationQRLoginScanScreen.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockAuthenticationQRLoginScanScreenState] {
        // Each of the presence statuses
        [.scanning, .noCameraAvailable, .noCameraAccess, .noCameraAvailableNoDisplayQR, .noCameraAccessNoDisplayQR]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let service: QRLoginServiceProtocol

        switch self {
        case .scanning:
            service = MockQRLoginService(withState: .scanningQR)
        case .noCameraAvailable:
            service = MockQRLoginService(withState: .failed(error: .noCameraAvailable))
        case .noCameraAccess:
            service = MockQRLoginService(withState: .failed(error: .noCameraAccess))
        case .noCameraAvailableNoDisplayQR:
            service = MockQRLoginService(withState: .failed(error: .noCameraAvailable), canDisplayQR: false)
        case .noCameraAccessNoDisplayQR:
            service = MockQRLoginService(withState: .failed(error: .noCameraAccess), canDisplayQR: false)
        }

        let viewModel = AuthenticationQRLoginScanViewModel(qrLoginService: service)
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [self, viewModel],
            AnyView(AuthenticationQRLoginScanScreen(context: viewModel.context))
        )
    }
}
