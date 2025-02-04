//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

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
    var point1: NSAttributedString { get }
    var point2: NSAttributedString { get }
}

enum AnalyticsPromptType {
    case newUser
    case upgrade
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
    
    /// The main part of the terms string that should be displayed.
    var mainTermsString: String {
        switch self {
        case .newUser:
            return VectorL10n.analyticsPromptTermsNewUser("%@")
        case .upgrade:
            return VectorL10n.analyticsPromptTermsUpgrade("%@")
        }
    }
    
    /// The tappable part of the terms string that should be displayed.
    var termsLinkString: String {
        switch self {
        case .newUser:
            return VectorL10n.analyticsPromptTermsLinkNewUser
        case .upgrade:
            return VectorL10n.analyticsPromptTermsLinkUpgrade
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

extension AnalyticsPromptType: CaseIterable { }

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
