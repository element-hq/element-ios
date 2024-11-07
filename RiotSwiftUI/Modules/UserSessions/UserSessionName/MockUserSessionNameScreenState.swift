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
enum MockUserSessionNameScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case initialName
    case empty
    case changedName
    
    /// The associated screen
    var screenType: Any.Type {
        UserSessionName.self
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let viewModel: UserSessionNameViewModel
        switch self {
        case .initialName:
            viewModel = UserSessionNameViewModel(sessionInfo: .mockPhone())
        case .empty:
            viewModel = UserSessionNameViewModel(sessionInfo: .mockPhone())
            viewModel.state.bindings.sessionName = ""
        case .changedName:
            viewModel = UserSessionNameViewModel(sessionInfo: .mockPhone())
            viewModel.state.bindings.sessionName = "iPhone SE"
        }
        
        return ([viewModel], AnyView(UserSessionName(viewModel: viewModel.context)))
    }
}
