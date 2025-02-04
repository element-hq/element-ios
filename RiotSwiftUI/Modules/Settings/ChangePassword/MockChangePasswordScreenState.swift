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
enum MockChangePasswordScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case allEmpty
    case cannotSubmit
    case canSubmit
    case canSubmitAndSignoutAllDevicesChecked
    
    /// The associated screen
    var screenType: Any.Type {
        ChangePasswordScreen.self
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let viewModel: ChangePasswordViewModel
        switch self {
        case .allEmpty:
            viewModel = ChangePasswordViewModel()
        case .cannotSubmit:
            viewModel = ChangePasswordViewModel(oldPassword: "12345678",
                                                newPassword1: "87654321")
        case .canSubmit:
            viewModel = ChangePasswordViewModel(oldPassword: "12345678",
                                                newPassword1: "87654321",
                                                newPassword2: "87654321")
        case .canSubmitAndSignoutAllDevicesChecked:
            viewModel = ChangePasswordViewModel(oldPassword: "12345678",
                                                newPassword1: "87654321",
                                                newPassword2: "87654321",
                                                signoutAllDevices: true)
        }
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [viewModel], AnyView(ChangePasswordScreen(viewModel: viewModel.context))
        )
    }
}
