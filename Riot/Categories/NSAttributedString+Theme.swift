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

/// Custom NSAttributedString.Key to specify the theme
let themeIdentifierAttributeName = NSAttributedString.Key("ThemeIdentifier")
/// Custom NSAttributedString.Key to specify a theme color by its name
let themeColorNameAttributeName = NSAttributedString.Key("ThemeColorName")

extension NSAttributedString {
    /// Fix foreground color attributes if this attributed string contains the `themeIdentifierAttributeName` and `foregroundColorNameAttributeName` attributes
    /// - Returns: a new attributed string with updated colors
    @objc func fixForegroundColor() -> NSAttributedString {
        let activeTheme = ThemeService.shared().theme
        
        // Check if a theme is defined for this attributed string
        var needUpdate = false
        self.vc_enumerateAttribute(themeIdentifierAttributeName) { (themeIdentifier: String, range: NSRange, _) in
            needUpdate = themeIdentifier != activeTheme.identifier
        }
        
        guard needUpdate else {
            return self
        }
        
        // Build a new attributedString with the proper colors if possible
        let mutableAttributedString = NSMutableAttributedString(attributedString: self)
        mutableAttributedString.vc_enumerateAttribute(themeColorNameAttributeName) { (colorName: String, range: NSRange, _) in
            if let color = ThemeColorResolver.getColorByName(colorName) {
                mutableAttributedString.addAttribute(.foregroundColor, value: color, range: range)
            }
        }
        return mutableAttributedString
    }
}

extension NSMutableAttributedString {
    /// Adds a theme color name attribute
    /// - Parameters:
    ///   - colorName: color name
    ///   - range:range for this attribute
    @objc func addThemeColorNameAttribute(_ colorName: String, range: NSRange) {
        self.addAttribute(themeColorNameAttributeName, value: colorName, range: range)
    }
    
    /// Adds a theme identifier attribute
    @objc func addThemeIdentifierAttribute() {
        self.addAttribute(themeIdentifierAttributeName, value: ThemeService.shared().theme.identifier, range: .init(location: 0, length: length))
    }
}
