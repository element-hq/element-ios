/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
