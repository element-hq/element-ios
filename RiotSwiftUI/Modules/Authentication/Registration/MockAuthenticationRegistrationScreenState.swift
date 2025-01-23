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
    case mas

    /// The associated screen
    var screenType: Any.Type {
        AuthenticationRegistrationScreen.self
    }

    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let viewModel: AuthenticationRegistrationViewModel
        switch self {
        case .matrixDotOrg:
            viewModel = AuthenticationRegistrationViewModel(homeserver: .mockMatrixDotOrg, showReplacementAppBanner: false)
        case .passwordOnly:
            viewModel = AuthenticationRegistrationViewModel(homeserver: .mockBasicServer, showReplacementAppBanner: false)
        case .passwordWithCredentials:
            viewModel = AuthenticationRegistrationViewModel(homeserver: .mockBasicServer, showReplacementAppBanner: false)
            viewModel.context.username = "alice"
            viewModel.context.password = "password"
            Task { await viewModel.confirmUsernameAvailability("alice") }
        case .passwordWithUsernameError:
            viewModel = AuthenticationRegistrationViewModel(homeserver: .mockBasicServer, showReplacementAppBanner: false)
            viewModel.state.hasEditedUsername = true
            Task { await viewModel.displayError(.usernameUnavailable(VectorL10n.authInvalidUserName)) }
        case .ssoOnly:
            viewModel = AuthenticationRegistrationViewModel(homeserver: .mockEnterpriseSSO, showReplacementAppBanner: false)
        case .fallback:
            viewModel = AuthenticationRegistrationViewModel(homeserver: .mockFallback, showReplacementAppBanner: false)
        case .mas:
            viewModel = AuthenticationRegistrationViewModel(homeserver: .init(address: "beta.matrix.org",
                                                                              showLoginForm: false,
                                                                              showRegistrationForm: false,
                                                                              showQRLogin: false,
                                                                              ssoIdentityProviders: []), // The initial discovery failed so the OIDC provider is not known.
                                                            showReplacementAppBanner: true)
        }
        
        // can simulate service and viewModel actions here if needs be.

        return (
            [viewModel], AnyView(AuthenticationRegistrationScreen(viewModel: viewModel.context))
        )
    }
}
