// 
// Copyright 2022 New Vector Ltd
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

import UIKit

/// `PresenceIndicatorView` is used to display a presence indicator over an avatar.
@objcMembers
@IBDesignable
final class PresenceIndicatorView: UIView {
    // MARK: - Internal Properties
    @IBInspectable var borderWidth: CGFloat = 0.0
    var borderColor: UIColor = ThemeService.shared().theme.backgroundColor
    
    // MARK: - Private Properties
    private let borderLayer = CALayer()
    
    // MARK: - Private Constants
    private enum Constants {
        static let borderLayerOffset: CGFloat = 1.0
    }
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: - Override
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // This sets up a slightly larger border layer to avoid common iOS
        // issue of having a very thin but noticeable additional border of
        // backgroundColor when using corner radius + borderWidth.
        self.layer.cornerRadius = self.frame.width / 2.0
        self.borderLayer.borderWidth = self.borderWidth + Constants.borderLayerOffset
        self.borderLayer.cornerRadius = self.layer.cornerRadius + Constants.borderLayerOffset
        self.borderLayer.frame = self.frame.withOffset(Constants.borderLayerOffset)
    }
    
    // MARK: - Internal Methods
    /// Updates presence indicator with given `MXPresence`.
    ///
    /// - Parameters:
    ///   - presence: `MXPresence` to display
    func setPresence(_ presence: MXPresence) {
        switch presence {
        case .online:
            self.backgroundColor = ThemeService.shared().theme.tintColor
            self.borderLayer.borderColor = self.borderColor.cgColor
        case .offline, .unavailable:
            self.backgroundColor = ThemeService.shared().theme.tabBarUnselectedItemTintColor
            self.borderLayer.borderColor = self.borderColor.cgColor
        default:
            self.backgroundColor = UIColor.clear
            self.borderLayer.borderColor = UIColor.clear.cgColor
        }
    }
}
    
// MARK: - Private Methods
private extension PresenceIndicatorView {
    func setup() {
        self.layer.addSublayer(borderLayer)
    }
}

// MARK: - CGRect Helper
private extension CGRect {
    /// Returns a `CGRect` with given offset on each side.
    ///
    /// - Parameters:
    ///   - offset: offset to apply
    /// - Returns: `CGRect` with given offset
    func withOffset(_ offset: CGFloat) -> CGRect {
        return CGRect(x: -offset, y: -offset,
                      width: self.width + 2.0 * offset,
                      height: self.height + 2.0 * offset)
    }
}
