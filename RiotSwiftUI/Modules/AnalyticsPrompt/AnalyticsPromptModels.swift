// File created from SimpleUserProfileExample
// $ createScreen.sh AnalyticsPrompt AnalyticsPrompt
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

// The state is never modified so this is unnecessary.
enum AnalyticsPromptStateAction { }

enum AnalyticsPromptViewAction {
    /// Enable analytics.
    case enable
    /// Disable analytics.
    case disable
    /// Open the service terms link.
    case openTermsURL
}

enum AnalyticsPromptViewModelResult {
    /// Enable analytics.
    case enable
    /// Disable analytics.
    case disable
}

struct AnalyticsPromptViewState: BindableState {
    /// The type of prompt to display.
    let promptType: AnalyticsPromptType
    /// The app's bundle display name.
    let appDisplayName: String
}

enum AnalyticsPromptType {
    case newUser
    case upgrade
}

extension AnalyticsPromptType {
    var description: String {
        switch self {
        case .newUser:
            return VectorL10n.analyticsPromptDescriptionNewUser
        case .upgrade:
            return VectorL10n.analyticsPromptDescriptionUpgrade
        }
    }
    
    var termsStrings: (String, String, String) {
        switch self {
        case .newUser:
            return (VectorL10n.analyticsPromptTermsStartNewUser,
                    VectorL10n.analyticsPromptTermsLinkNewUser,
                    VectorL10n.analyticsPromptTermsEndNewUser)
        case .upgrade:
            return (VectorL10n.analyticsPromptTermsStartUpgrade,
                    VectorL10n.analyticsPromptTermsLinkUpgrade,
                    VectorL10n.analyticsPromptTermsEndUpgrade)
        }
    }
    
    var enableButtonTitle: String {
        switch self {
        case .newUser:
            return VectorL10n.enable
        case .upgrade:
            return VectorL10n.analyticsPromptYes
        }
    }
    
    var disableButtonTitle: String {
        switch self {
        case .newUser:
            return VectorL10n.cancel
        case .upgrade:
            return VectorL10n.analyticsPromptStop
        }
    }
}

extension AnalyticsPromptType: CaseIterable { }

extension AnalyticsPromptType: Identifiable {
    var id: Self { self }
}
