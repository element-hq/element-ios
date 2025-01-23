// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
        self.layer.cornerRadius = self.frame.width / 2.0
        self.borderLayer.borderWidth = self.borderWidth + Constants.borderLayerOffset
        self.borderLayer.cornerRadius = self.layer.cornerRadius + Constants.borderLayerOffset
        self.borderLayer.frame = self.frame.withOffset(Constants.borderLayerOffset)
    }
    
    // MARK: - Internal Methods
    /// Configures the view and starts listening Presence updates for given user.
    ///
    /// - Parameters:
    ///   - userId: the user id
    ///   - presence: the initial Presence of the user
    func configure(userId: String, presence: MXPresence) {
        setPresence(presence)
        self.listener = PresenceIndicatorListener(userId: userId,
                                                  presence: presence) { [weak self] presence in
            guard let self = self else { return }
            self.setPresence(presence)
        }
    }

    /// Stop listening to Presence updates and hides the indicator.
    /// This should be called before reuse or if current room moves from direct to non-direct.
    func stopListeningPresenceUpdates() {
        self.listener = nil
        self.isHidden = true
    }
}
    
// MARK: - Private Methods
private extension PresenceIndicatorView {
    func setup() {
        self.layer.addSublayer(borderLayer)
    }

    /// Updates presence indicator with given `MXPresence`.
    ///
    /// - Parameters:
    ///   - presence: `MXPresence` to display
    func setPresence(_ presence: MXPresence) {
        switch presence {
        case .online:
            self.backgroundColor = ThemeService.shared().theme.tintColor
            self.borderLayer.borderColor = self.borderColor.cgColor
            self.isHidden = false
        case .offline, .unavailable:
            self.backgroundColor = ThemeService.shared().theme.tabBarUnselectedItemTintColor
            self.borderLayer.borderColor = self.borderColor.cgColor
            self.isHidden = false
        default:
            self.backgroundColor = UIColor.clear
            self.borderLayer.borderColor = UIColor.clear.cgColor
            self.isHidden = true
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
        return CGRect(x: -offset, y: -offset,
                      width: self.width + 2.0 * offset,
                      height: self.height + 2.0 * offset)
    }
}
