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
enum MockAnalyticsPromptScreenState: MockScreenState, CaseIterable {
    /// The type of prompt to display.
    case promptType(AnalyticsPromptType)
    
    /// The associated screen
    var screenType: Any.Type {
        AnalyticsPrompt.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockAnalyticsPromptScreenState] {
        AnalyticsPromptType.allCases.map { MockAnalyticsPromptScreenState.promptType($0) }
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let promptType: AnalyticsPromptType
        switch self {
        case .promptType(let analyticsPromptType):
            promptType = analyticsPromptType
        }
        let viewModel = AnalyticsPromptViewModel(promptType: promptType,
                                                 strings: MockAnalyticsPromptStrings(),
                                                 termsURL: URL(string: "https://element.io/cookie-policy")!)
        
        return (
            [promptType, viewModel],
            AnyView(AnalyticsPrompt(viewModel: viewModel.context)
                .environmentObject(AvatarViewModel.withMockedServices()))
        )
    }
}
