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

/// Delegate for `PresenceIndicatorView`.
@objc protocol PresenceIndicatorViewDelegate: AnyObject {
    func presenceIndicatorViewDidUpdateVisibility(_ presenceIndicatorView: PresenceIndicatorView, isHidden: Bool)
}

/// `PresenceIndicatorView` is used to display a presence indicator over an avatar.
@objcMembers
@IBDesignable
final class PresenceIndicatorView: UIView {
    // MARK: - Internal Properties

    @IBInspectable var borderWidth: CGFloat = 0.0
    var borderColor: UIColor = ThemeService.shared().theme.backgroundColor
    
    // MARK: - Properties

    // MARK: Private

    private let borderLayer = CALayer()
    private var listener: PresenceIndicatorListener?

    // MARK: Internal

    weak var delegate: PresenceIndicatorViewDelegate?

    // MARK: Override

    override var isHidden: Bool {
        didSet {
            if oldValue != isHidden, let delegate = delegate {
                delegate.presenceIndicatorViewDidUpdateVisibility(self, isHidden: isHidden)
            }
        }
    }

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
        layer.cornerRadius = frame.width / 2.0
        borderLayer.borderWidth = borderWidth + Constants.borderLayerOffset
        borderLayer.cornerRadius = layer.cornerRadius + Constants.borderLayerOffset
        borderLayer.frame = frame.withOffset(Constants.borderLayerOffset)
    }
    
    // MARK: - Internal Methods

    /// Configures the view and starts listening Presence updates for given user.
    ///
    /// - Parameters:
    ///   - userId: the user id
    ///   - presence: the initial Presence of the user
    func configure(userId: String, presence: MXPresence) {
        setPresence(presence)
        listener = PresenceIndicatorListener(userId: userId,
                                             presence: presence) { [weak self] presence in
            guard let self = self else { return }
            self.setPresence(presence)
        }
    }

    /// Stop listening to Presence updates and hides the indicator.
    /// This should be called before reuse or if current room moves from direct to non-direct.
    func stopListeningPresenceUpdates() {
        listener = nil
        isHidden = true
    }
}
    
// MARK: - Private Methods

private extension PresenceIndicatorView {
    func setup() {
        layer.addSublayer(borderLayer)
    }

    /// Updates presence indicator with given `MXPresence`.
    ///
    /// - Parameters:
    ///   - presence: `MXPresence` to display
    func setPresence(_ presence: MXPresence) {
        switch presence {
        case .online:
            backgroundColor = ThemeService.shared().theme.tintColor
            borderLayer.borderColor = borderColor.cgColor
            isHidden = false
        case .offline, .unavailable:
            backgroundColor = ThemeService.shared().theme.tabBarUnselectedItemTintColor
            borderLayer.borderColor = borderColor.cgColor
            isHidden = false
        default:
            backgroundColor = UIColor.clear
            borderLayer.borderColor = UIColor.clear.cgColor
            isHidden = true
        }
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
        CGRect(x: -offset, y: -offset,
               width: width + 2.0 * offset,
               height: height + 2.0 * offset)
    }
}
