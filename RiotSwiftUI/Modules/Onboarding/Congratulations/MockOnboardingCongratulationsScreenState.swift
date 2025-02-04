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
enum MockOnboardingCongratulationsScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case regular
    case personalizationDisabled
    
    /// The associated screen
    var screenType: Any.Type {
        OnboardingCongratulationsScreen.self
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let viewModel: OnboardingCongratulationsViewModel
        
        switch self {
        case .regular:
            viewModel = OnboardingCongratulationsViewModel(userId: "@testuser:example.com")
        case .personalizationDisabled:
            viewModel = OnboardingCongratulationsViewModel(userId: "@testuser:example.com", personalizationDisabled: true)
        }
        
        return (
            [self, viewModel],
            AnyView(OnboardingCongratulationsScreen(viewModel: viewModel.context))
        )
    }
}
