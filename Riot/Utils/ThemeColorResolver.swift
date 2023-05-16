// 
// Copyright 2023 New Vector Ltd
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
