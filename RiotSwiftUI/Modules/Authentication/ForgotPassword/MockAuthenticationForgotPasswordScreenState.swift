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
enum MockAuthenticationForgotPasswordScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case emptyAddress
    case enteredAddress
    case hasSentEmail
    
    /// The associated screen
    var screenType: Any.Type {
        AuthenticationForgotPasswordScreen.self
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let viewModel: AuthenticationForgotPasswordViewModel
        switch self {
        case .emptyAddress:
            viewModel = AuthenticationForgotPasswordViewModel(homeserver: .mockMatrixDotOrg,
                                                              emailAddress: "")
        case .enteredAddress:
            viewModel = AuthenticationForgotPasswordViewModel(homeserver: .mockMatrixDotOrg,
                                                              emailAddress: "test@example.com")
        case .hasSentEmail:
            viewModel = AuthenticationForgotPasswordViewModel(homeserver: .mockMatrixDotOrg,
                                                              emailAddress: "test@example.com")
            Task { await viewModel.updateForSentEmail() }
        }
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [viewModel], AnyView(AuthenticationForgotPasswordScreen(viewModel: viewModel.context))
        )
    }
}
