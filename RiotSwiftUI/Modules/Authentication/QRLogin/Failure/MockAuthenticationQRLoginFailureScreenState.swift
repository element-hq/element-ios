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
enum MockAuthenticationQRLoginFailureScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case invalidQR
    case deviceNotSupported
    case requestDenied
    case requestTimedOut
    
    /// The associated screen
    var screenType: Any.Type {
        AuthenticationQRLoginFailureScreen.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockAuthenticationQRLoginFailureScreenState] {
        // Each of the presence statuses
        [.invalidQR, .deviceNotSupported, .requestDenied, .requestTimedOut]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let viewModel: AuthenticationQRLoginFailureViewModel

        switch self {
        case .invalidQR:
            viewModel = .init(qrLoginService: MockQRLoginService(withState: .failed(error: .invalidQR)))
        case .deviceNotSupported:
            viewModel = .init(qrLoginService: MockQRLoginService(withState: .failed(error: .deviceNotSupported)))
        case .requestDenied:
            viewModel = .init(qrLoginService: MockQRLoginService(withState: .failed(error: .requestDenied)))
        case .requestTimedOut:
            viewModel = .init(qrLoginService: MockQRLoginService(withState: .failed(error: .requestTimedOut)))
        }
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [self, viewModel],
            AnyView(AuthenticationQRLoginFailureScreen(context: viewModel.context))
        )
    }
}
