/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

extension UIButton {
    
    /// Enable multiple lines for button title.
    ///
    /// - Parameter textAlignment: Title text alignement. Default `NSTextAlignment.center`.
    func vc_enableMultiLinesTitle(textAlignment: NSTextAlignment = .center) {
        guard let titleLabel = self.titleLabel else {
            return
        }
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = textAlignment
    }
        
    /// Set background color as an image.
    /// Useful to automatically adjust highlighted background if `adjustsImageWhenHighlighted` property is set to true or disabled background when `adjustsImageWhenDisabled`is set to true.
    ///
    /// - Parameters:
    ///   - color: The background color to set as an image.
    ///   - state: The control state for wich to apply this color.
    func vc_setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        let image = UIImage.vc_image(from: color)
        self.setBackgroundImage(image, for: state)
    }
        
    /// Shortcut to button label property `adjustsFontForContentSizeCategory`
    @IBInspectable
    var vc_adjustsFontForContentSizeCategory: Bool {
        get {
            return self.titleLabel?.adjustsFontForContentSizeCategory ?? false
        }
        set {
            self.titleLabel?.adjustsFontForContentSizeCategory = newValue
        }
    }
    
    /// Set title font and enable Dynamic Type support
    func vc_setTitleFont(_ font: UIFont) {
        self.vc_adjustsFontForContentSizeCategory = true
        self.titleLabel?.font = font
    }
}
