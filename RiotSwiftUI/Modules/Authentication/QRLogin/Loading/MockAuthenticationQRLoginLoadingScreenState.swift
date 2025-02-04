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
enum MockAuthenticationQRLoginLoadingScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case connectingToDevice
    case waitingForRemoteSignIn
    case completed
    
    /// The associated screen
    var screenType: Any.Type {
        AuthenticationQRLoginLoadingScreen.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockAuthenticationQRLoginLoadingScreenState] {
        // Each of the presence statuses
        [.connectingToDevice, .waitingForRemoteSignIn, .completed]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let viewModel: AuthenticationQRLoginLoadingViewModel

        switch self {
        case .connectingToDevice:
            viewModel = .init(qrLoginService: MockQRLoginService(withState: .connectingToDevice))
        case .waitingForRemoteSignIn:
            viewModel = .init(qrLoginService: MockQRLoginService(withState: .waitingForRemoteSignIn))
        case .completed:
            viewModel = .init(qrLoginService: MockQRLoginService(withState: .completed(session: "", securityCompleted: true)))
        }
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [self, viewModel],
            AnyView(AuthenticationQRLoginLoadingScreen(context: viewModel.context))
        )
    }
}
