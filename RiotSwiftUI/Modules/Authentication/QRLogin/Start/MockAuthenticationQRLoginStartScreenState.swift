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
enum MockAuthenticationQRLoginStartScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case displayQREnabled
    case displayQRDisabled
    
    /// The associated screen
    var screenType: Any.Type {
        AuthenticationQRLoginStartScreen.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockAuthenticationQRLoginStartScreenState] {
        // Each of the presence statuses
        [.displayQREnabled, .displayQRDisabled]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let service: QRLoginServiceProtocol

        switch self {
        case .displayQREnabled:
            service = MockQRLoginService(canDisplayQR: true)
        case .displayQRDisabled:
            service = MockQRLoginService(canDisplayQR: false)
        }

        let viewModel = AuthenticationQRLoginStartViewModel(qrLoginService: service)
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [self, viewModel],
            AnyView(AuthenticationQRLoginStartScreen(context: viewModel.context))
        )
    }
}
