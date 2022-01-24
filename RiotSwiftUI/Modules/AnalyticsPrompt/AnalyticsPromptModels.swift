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
    /// Localized attributed strings created in the coordinator.
    let strings: AnalyticsPromptStringsProtocol
}

/// A collection of strings for the UI that need to be created in
/// the coordinator or mocked in the RiotSwiftUI target.
protocol AnalyticsPromptStringsProtocol {
    var appDisplayName: String { get }
    
    var point1: NSAttributedString { get }
    var point2: NSAttributedString { get }
    
    var termsNewUser: NSAttributedString { get }
    var termsUpgrade: NSAttributedString { get }
}

enum AnalyticsPromptType {
    case newUser(termsString: NSAttributedString)
    case upgrade(termsString: NSAttributedString)
}

extension AnalyticsPromptType {
    /// The main description string that should be displayed.
    var message: String {
        switch self {
        case .newUser:
            return VectorL10n.analyticsPromptMessageNewUser(AppInfo.current.displayName)
        case .upgrade:
            return VectorL10n.analyticsPromptMessageUpgrade
        }
    }
    
    /// The terms string that should be displayed.
    var termsStrings: NSAttributedString {
        switch self {
        case .newUser(let termsString), .upgrade(let termsString):
            return termsString
        }
    }
    
    /// The title for the enable button.
    var enableButtonTitle: String {
        switch self {
        case .newUser:
            return VectorL10n.enable
        case .upgrade:
            return VectorL10n.analyticsPromptYes
        }
    }
    
    /// The title for the disable button.
    var disableButtonTitle: String {
        switch self {
        case .newUser:
            return VectorL10n.analyticsPromptNotNow
        case .upgrade:
            return VectorL10n.analyticsPromptStop
        }
    }
}

extension AnalyticsPromptType: CaseIterable {
    static var allCases: [AnalyticsPromptType] {
        let strings = MockAnalyticsPromptStrings()
        return [
            .newUser(termsString: strings.termsNewUser),
            .upgrade(termsString: strings.termsUpgrade)
        ]
    }
}

extension AnalyticsPromptType: Identifiable {
    var id: String {
        switch self {
        case .newUser:
            return "newUser"
        case .upgrade:
            return "upgrade"
        }
    }
}

// For the RiotSwiftUI target presentation.
extension AnalyticsPromptType: CustomStringConvertible {
    var description: String { id }
}
