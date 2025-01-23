//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// A Modifier to be called from the top-most SwiftUI view before being added to a HostViewController.
///
/// Provides any app level configuration the SwiftUI hierarchy might need (E.g. to monitor theme changes).
struct VectorContentModifier: ViewModifier {
    @ObservedObject private var themePublisher = ThemePublisher.shared
    @Environment(\.layoutDirection) private var defaultLayoutDirection
    
    /// The layout direction to use, taking into account the build settings. SwiftUI generally
    /// handles RTL well enough, but we match the behaviour used in UIKit to avoid mixed layouts.
    var layoutDirection: LayoutDirection {
        BuildSettings.disableRightToLeftLayout ? .leftToRight : defaultLayoutDirection
    }
    
    func body(content: Content) -> some View {
        content
            .theme(themePublisher.theme)
            .environment(\.layoutDirection, layoutDirection)
    }
}

extension View {
    func vectorContent() -> some View {
        modifier(VectorContentModifier())
    }
}
