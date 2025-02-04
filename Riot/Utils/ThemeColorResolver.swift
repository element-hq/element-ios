// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Utility struct to get a theme color by its name
struct ThemeColorResolver {
    private static var theme: Theme?
    private static var colorsTable: [String: UIColor] = [:]
    private static let queue = DispatchQueue(label: "io.element.ThemeColorResolver.queue", qos: .userInteractive)

    private static func setTheme(theme: Theme) {
        queue.sync {
            guard self.theme?.identifier != theme.identifier else {
                return
            }
            self.theme = theme
            colorsTable = [:]
            let mirror = Mirror(reflecting: theme.colors)
            for child in mirror.children {
                if let colorName = child.label {
                    colorsTable[colorName] = child.value as? UIColor
                }
            }
        }
    }
    
    /// Finds a color by its name in the current theme colors
    /// - Parameter name: color name
    /// - Returns: the corresponding color or nil
    static func getColorByName(_ name: String) -> UIColor? {
        setTheme(theme: ThemeService.shared().theme)
        return colorsTable[name]
    }
}
