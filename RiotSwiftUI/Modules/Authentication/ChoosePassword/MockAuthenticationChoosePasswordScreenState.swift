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
enum MockAuthenticationChoosePasswordScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case emptyPassword
    case enteredInvalidPassword
    case enteredValidPassword
    case enteredValidPasswordAndSignoutAllDevicesChecked
    
    /// The associated screen
    var screenType: Any.Type {
        AuthenticationChoosePasswordScreen.self
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let viewModel: AuthenticationChoosePasswordViewModel
        switch self {
        case .emptyPassword:
            viewModel = AuthenticationChoosePasswordViewModel()
        case .enteredInvalidPassword:
            viewModel = AuthenticationChoosePasswordViewModel(password: "1234")
        case .enteredValidPassword:
            viewModel = AuthenticationChoosePasswordViewModel(password: "12345678")
        case .enteredValidPasswordAndSignoutAllDevicesChecked:
            viewModel = AuthenticationChoosePasswordViewModel(password: "12345678", signoutAllDevices: true)
        }
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [viewModel], AnyView(AuthenticationChoosePasswordScreen(viewModel: viewModel.context))
        )
    }
}
