// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
