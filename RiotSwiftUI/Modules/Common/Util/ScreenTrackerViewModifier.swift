//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// `ScreenTrackerViewModifier` is a helper class used to track PostHog screen from SwiftUI screens.
struct ScreenTrackerViewModifier: ViewModifier {
    let screen: AnalyticsScreen
    
    @ViewBuilder
    func body(content: Content) -> some View {
        content
            .onAppear {
                #if canImport(MatrixSDK)
                Analytics.shared.trackScreen(screen)
                #endif
            }
    }
}

extension View {
    func track(screen: AnalyticsScreen) -> some View {
        modifier(ScreenTrackerViewModifier(screen: screen))
    }
}
