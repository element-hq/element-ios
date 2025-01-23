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
enum MockAuthenticationReCaptchaScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case standard
    
    /// The associated screen
    var screenType: Any.Type {
        AuthenticationReCaptchaScreen.self
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let viewModel: AuthenticationReCaptchaViewModel
        switch self {
        case .standard:
            viewModel = AuthenticationReCaptchaViewModel(siteKey: "12345", homeserverURL: URL(string: "https://matrix-client.matrix.org")!)
        }
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [viewModel], AnyView(AuthenticationReCaptchaScreen(viewModel: viewModel.context))
        )
    }
}
