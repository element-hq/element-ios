//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import DesignKit
import Foundation

extension ThemeIdentifier {
    fileprivate static let defaultTheme = DefaultThemeSwiftUI()
    fileprivate static let darkTheme = DarkThemeSwiftUI()
    /// Extension to `ThemeIdentifier` for getting the SwiftUI theme.
    public var themeSwiftUI: ThemeSwiftUI {
        switch self {
        case .light:
            return Self.defaultTheme
        case .dark, .black:
            return Self.darkTheme
        }
    }
}
