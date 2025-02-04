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
enum MockOnboardingSplashScreenScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case animated
    
    /// The associated screen
    var screenType: Any.Type {
        OnboardingSplashScreen.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockOnboardingSplashScreenScreenState] {
        [.animated]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let viewModel = OnboardingSplashScreenViewModel()
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [false, viewModel],
            AnyView(OnboardingSplashScreen(viewModel: viewModel.context))
        )
    }
}
