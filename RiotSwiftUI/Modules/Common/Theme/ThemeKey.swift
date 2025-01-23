//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import DesignKit
import Foundation
import SwiftUI

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = ThemePublisher.shared.theme
}

extension EnvironmentValues {
    var theme: ThemeSwiftUI {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    /// A theme modifier for setting the theme for this view and all its descendants in the hierarchy.
    /// - Parameter theme: A theme to be set as the environment value.
    /// - Returns: The target view with the theme applied.
    func theme(_ theme: ThemeSwiftUI) -> some View {
        environment(\.theme, theme)
    }
}

extension View {
    /// A theme modifier for setting the theme by id for this view and all its descendants in the hierarchy.
    /// - Parameter themeId: ThemeIdentifier of a theme to be set as the environment value.
    /// - Returns: The target view with the theme applied.
    func theme(_ themeId: ThemeIdentifier) -> some View {
        environment(\.theme, themeId.themeSwiftUI)
    }
}
