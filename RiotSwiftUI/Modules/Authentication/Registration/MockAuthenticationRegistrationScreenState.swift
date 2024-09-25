//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

/// Using an enum for the screen allows you define the different state cases with
/// the relevant associated data for each case.
enum MockAuthenticationRegistrationScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case matrixDotOrg
    case passwordOnly
    case passwordWithCredentials
    case passwordWithUsernameError
    case ssoOnly
    case fallback

    /// The associated screen
    var screenType: Any.Type {
        AuthenticationRegistrationScreen.self
    }

    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let viewModel: AuthenticationRegistrationViewModel
        switch self {
        case .matrixDotOrg:
            viewModel = AuthenticationRegistrationViewModel(homeserver: .mockMatrixDotOrg)
        case .passwordOnly:
            viewModel = AuthenticationRegistrationViewModel(homeserver: .mockBasicServer)
        case .passwordWithCredentials:
            viewModel = AuthenticationRegistrationViewModel(homeserver: .mockBasicServer)
            viewModel.context.username = "alice"
            viewModel.context.password = "password"
            Task { await viewModel.confirmUsernameAvailability("alice") }
        case .passwordWithUsernameError:
            viewModel = AuthenticationRegistrationViewModel(homeserver: .mockBasicServer)
            viewModel.state.hasEditedUsername = true
            Task { await viewModel.displayError(.usernameUnavailable(VectorL10n.authInvalidUserName)) }
        case .ssoOnly:
            viewModel = AuthenticationRegistrationViewModel(homeserver: .mockEnterpriseSSO)
        case .fallback:
            viewModel = AuthenticationRegistrationViewModel(homeserver: .mockFallback)
        }
        
        // can simulate service and viewModel actions here if needs be.

        return (
            [viewModel], AnyView(AuthenticationRegistrationScreen(viewModel: viewModel.context))
        )
    }
}
