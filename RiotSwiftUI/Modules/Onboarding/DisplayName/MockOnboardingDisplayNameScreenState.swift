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
enum MockOnboardingDisplayNameScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case emptyTextField
    case filledTextField(displayName: String)
    case longDisplayName(displayName: String)
    
    /// The associated screen
    var screenType: Any.Type {
        OnboardingDisplayNameScreen.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockOnboardingDisplayNameScreenState] {
        [
            MockOnboardingDisplayNameScreenState.emptyTextField,
            MockOnboardingDisplayNameScreenState.filledTextField(displayName: "Test User"),
            MockOnboardingDisplayNameScreenState.longDisplayName(displayName: """
            Bacon ipsum dolor amet filet mignon chicken kevin andouille. Doner shoulder beef, brisket bresaola turkey jowl venison. Ham hock cow turducken, chislic venison doner short loin strip steak tri-tip jowl. Sirloin pork belly hamburger ribeye. Tail capicola alcatra short ribs turkey doner.
            """)
        ]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let viewModel: OnboardingDisplayNameViewModel
        switch self {
        case .emptyTextField:
            viewModel = OnboardingDisplayNameViewModel()
        case .filledTextField(let displayName), .longDisplayName(displayName: let displayName):
            viewModel = OnboardingDisplayNameViewModel(displayName: displayName)
        }
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [self, viewModel], AnyView(OnboardingDisplayNameScreen(viewModel: viewModel.context))
        )
    }
}
