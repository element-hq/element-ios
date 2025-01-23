//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

// MARK: - Coordinator

/// The content displayed in a single splash screen page.
struct OnboardingSplashScreenPageContent {
    let title: String
    let message: String
    let image: ImageAsset
    let darkImage: ImageAsset
}

// MARK: View model

enum OnboardingSplashScreenViewModelResult {
    case register
    case login
}

// MARK: View

struct OnboardingSplashScreenViewState: BindableState, CustomDebugStringConvertible {
    /// The colours of the background gradient shown behind the 4 pages.
    private let gradientColors = [
        Color(red: 0.95, green: 0.98, blue: 0.96),
        Color(red: 0.89, green: 0.96, blue: 0.97),
        Color(red: 0.95, green: 0.89, blue: 0.97),
        Color(red: 0.81, green: 0.95, blue: 0.91),
        Color(red: 0.95, green: 0.98, blue: 0.96)
    ]
    
    /// An array containing all content of the carousel pages
    let content: [OnboardingSplashScreenPageContent]
    var bindings: OnboardingSplashScreenBindings
    
    /// Custom debug description to reduce noise in the logs.
    var debugDescription: String {
        "OnboardingSplashScreenViewState at page \(bindings.pageIndex)."
    }
    
    /// The background gradient for all 4 pages and the hidden page at the start of the carousel.
    var backgroundGradient: Gradient {
        // Include the extra stop for the hidden page at the start of the carousel.
        let hiddenPageColor = gradientColors[gradientColors.count - 2]
        return Gradient(colors: [hiddenPageColor] + gradientColors)
    }
    
    init() {
        // The pun doesn't translate, so we only use it for English.
        let locale = Locale.current
        let page4Title = locale.identifier.hasPrefix("en") ? "Cut the slack from teams." : VectorL10n.onboardingSplashPage4TitleNoPun
        
        content = [
            OnboardingSplashScreenPageContent(title: VectorL10n.onboardingSplashPage1Title,
                                              message: VectorL10n.onboardingSplashPage1Message,
                                              image: Asset.Images.onboardingSplashScreenPage1,
                                              darkImage: Asset.Images.onboardingSplashScreenPage1Dark),
            OnboardingSplashScreenPageContent(title: VectorL10n.onboardingSplashPage2Title,
                                              message: VectorL10n.onboardingSplashPage2Message,
                                              image: Asset.Images.onboardingSplashScreenPage2,
                                              darkImage: Asset.Images.onboardingSplashScreenPage2Dark),
            OnboardingSplashScreenPageContent(title: VectorL10n.onboardingSplashPage3Title,
                                              message: VectorL10n.onboardingSplashPage3Message,
                                              image: Asset.Images.onboardingSplashScreenPage3,
                                              darkImage: Asset.Images.onboardingSplashScreenPage3Dark),
            OnboardingSplashScreenPageContent(title: page4Title,
                                              message: VectorL10n.onboardingSplashPage4Message,
                                              image: Asset.Images.onboardingSplashScreenPage4,
                                              darkImage: Asset.Images.onboardingSplashScreenPage4Dark)
        ]
        bindings = OnboardingSplashScreenBindings()
    }
}

struct OnboardingSplashScreenBindings {
    var pageIndex = 0
}

enum OnboardingSplashScreenViewAction {
    case register
    case login
    case nextPage
    case previousPage
    case hiddenPage
}
