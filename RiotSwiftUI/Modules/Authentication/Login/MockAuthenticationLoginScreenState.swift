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
enum MockAuthenticationLoginScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case matrixDotOrg
    case passwordOnly
    case passwordWithCredentials
    case ssoOnly
    case fallback

    /// The associated screen
    var screenType: Any.Type {
        AuthenticationLoginScreen.self
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let viewModel: AuthenticationLoginViewModel
        switch self {
        case .matrixDotOrg:
            viewModel = AuthenticationLoginViewModel(homeserver: .mockMatrixDotOrg)
        case .passwordOnly:
            viewModel = AuthenticationLoginViewModel(homeserver: .mockBasicServer)
        case .passwordWithCredentials:
            viewModel = AuthenticationLoginViewModel(homeserver: .mockBasicServer)
            viewModel.context.username = "alice"
            viewModel.context.password = "password"
        case .ssoOnly:
            viewModel = AuthenticationLoginViewModel(homeserver: .mockEnterpriseSSO)
        case .fallback:
            viewModel = AuthenticationLoginViewModel(homeserver: .mockFallback)
        }
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [viewModel], AnyView(AuthenticationLoginScreen(viewModel: viewModel.context))
        )
    }
}
