// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import Reusable

final class RoomAvatarView: AvatarView, NibOwnerLoadable {
    
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
        
        self.avatarImageView.layer.cornerRadius = self.avatarImageView.bounds.height/2
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
            self.vc_setupAccessibilityTraitsButton(withTitle: VectorL10n.roomAvatarViewAccessibilityLabel, hint: VectorL10n.roomAvatarViewAccessibilityHint, isEnabled: true)
        } else {
            self.vc_setupAccessibilityTraitsImage(withTitle: VectorL10n.roomAvatarViewAccessibilityLabel)
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
}
