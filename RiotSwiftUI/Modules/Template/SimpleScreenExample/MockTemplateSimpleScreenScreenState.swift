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
enum MockTemplateSimpleScreenScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case promptType(TemplateSimpleScreenPromptType)
    
    /// The associated screen
    var screenType: Any.Type {
        TemplateSimpleScreen.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockTemplateSimpleScreenScreenState] {
        // Each of the presence statuses
        TemplateSimpleScreenPromptType.allCases.map(MockTemplateSimpleScreenScreenState.promptType)
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let promptType: TemplateSimpleScreenPromptType
        switch self {
        case .promptType(let type):
            promptType = type
        }
        let viewModel = TemplateSimpleScreenViewModel(promptType: promptType)
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [promptType, viewModel],
            AnyView(TemplateSimpleScreen(viewModel: viewModel.context)
                .environmentObject(AvatarViewModel.withMockedServices()))
        )
    }
}
