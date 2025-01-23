// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Reusable

final class SpaceAvatarView: AvatarView, NibOwnerLoadable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let cornerRadius: CGFloat = 8.0
    }
    
    // MARK: - Properties

    // MARK: Outlets
    
    @IBOutlet private weak var cameraBadgeContainerView: UIView!
    
    // MARK: Public
    
    var showCameraBadgeOnFallbackImage: Bool = false
    
    // MARK: - Setup
    
    private func commonInit() {
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadNibContent()
        self.commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
        self.commonInit()
    }
    
    // MARK: - Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Ensure we keep a rounded corner if the width is less than 2 * Constants.cornerRadius
        self.avatarImageView.layer.cornerRadius = max(2.0, min(self.avatarImageView.bounds.width / 4, Constants.cornerRadius))
    }
    
    // MARK: - Public
    
    override func fill(with viewData: AvatarViewDataProtocol) {
        self.updateAvatarImageView(with: viewData)

        // Fix layoutSubviews not triggered issue
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setNeedsLayout()
        }
    }
    
    // MARK: - Overrides
    
    override func updateAccessibilityTraits() {
        if self.isUserInteractionEnabled {
            self.vc_setupAccessibilityTraitsButton(withTitle: VectorL10n.spaceAvatarViewAccessibilityLabel, hint: VectorL10n.spaceAvatarViewAccessibilityHint, isEnabled: true)
        } else {
            self.vc_setupAccessibilityTraitsImage(withTitle: VectorL10n.spaceAvatarViewAccessibilityLabel)
        }
    }
    
    override func updateAvatarImageView(with viewData: AvatarViewDataProtocol) {
        super.updateAvatarImageView(with: viewData)
        
        let hideCameraBadge: Bool
        
        if self.showCameraBadgeOnFallbackImage {
            hideCameraBadge = viewData.avatarUrl != nil
        } else {
            hideCameraBadge = true
        }
        
        self.cameraBadgeContainerView.isHidden = hideCameraBadge
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)
        
        self.avatarImageView.defaultBackgroundColor = theme.colors.tile
    }
}
