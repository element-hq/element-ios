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
enum MockAuthenticationServerSelectionScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case matrix
    case emptyAddress
    case invalidAddress
    case login
    case nonModal
    case mas
    
    /// The associated screen
    var screenType: Any.Type {
        AuthenticationServerSelectionScreen.self
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let viewModel: AuthenticationServerSelectionViewModel
        switch self {
        case .matrix:
            viewModel = AuthenticationServerSelectionViewModel(homeserverAddress: "matrix.org",
                                                               flow: .register,
                                                               hasModalPresentation: true)
        case .emptyAddress:
            viewModel = AuthenticationServerSelectionViewModel(homeserverAddress: "",
                                                               flow: .register,
                                                               hasModalPresentation: true)
        case .invalidAddress:
            viewModel = AuthenticationServerSelectionViewModel(homeserverAddress: "thisisbad",
                                                               flow: .register,
                                                               hasModalPresentation: true)
            Task { await viewModel.displayError(.footerMessage(VectorL10n.errorCommonMessage)) }
        case .login:
            viewModel = AuthenticationServerSelectionViewModel(homeserverAddress: "matrix.org",
                                                               flow: .login,
                                                               hasModalPresentation: true)
        case .nonModal:
            viewModel = AuthenticationServerSelectionViewModel(homeserverAddress: "matrix.org",
                                                               flow: .register,
                                                               hasModalPresentation: false)
        case .mas:
            viewModel = AuthenticationServerSelectionViewModel(homeserverAddress: "beta.matrix.org",
                                                               flow: .register,
                                                               hasModalPresentation: false)
            Task { await viewModel.displayError(.requiresReplacementApp) }
        }
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [viewModel], AnyView(AuthenticationServerSelectionScreen(viewModel: viewModel.context))
        )
    }
}
