//
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
                .addDependency(MockAvatarService.example))
        )
    }
}
