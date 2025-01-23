//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// Metrics used across the entire onboarding flow.
struct OnboardingMetrics {
    static let maxContentHeight: CGFloat = 750
    
    /// The padding used between the top of the main content and the navigation bar.
    static let topPaddingToNavigationBar: CGFloat = 16
    /// The padding used between the footer and the bottom of the view.
    static let actionButtonBottomPadding: CGFloat = 24
    /// The width/height used for the main icon shown in most of the screens.
    static let iconSize: CGFloat = 90
    
    /// The padding used to the top of the view for breaker screens that don't have a navigation bar.
    static let breakerScreenTopPadding: CGFloat = 80
    static let breakerScreenIconBottomPadding: CGFloat = 42
    
    /// The height to use for top/bottom spacers to pad the views to fit the `maxContentHeight`.
    static func spacerHeight(in geometry: GeometryProxy) -> CGFloat {
        max(0, (geometry.size.height - maxContentHeight) / 2)
    }
}
