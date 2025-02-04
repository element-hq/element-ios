// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import Reusable

final class UserAvatarView: AvatarView {
    
    // MARK: - Setup
    
    private func commonInit() {
        let avatarImageView = MXKImageView()
        avatarImageView.frame = self.frame
        self.vc_addSubViewMatchingParent(avatarImageView)
        self.avatarImageView = avatarImageView
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    // MARK: - Overrides
    
    override func updateAccessibilityTraits() {
        if self.isUserInteractionEnabled {
            self.vc_setupAccessibilityTraitsButton(withTitle: VectorL10n.userAvatarViewAccessibilityLabel, hint: VectorL10n.userAvatarViewAccessibilityHint, isEnabled: true)
        } else {
            self.vc_setupAccessibilityTraitsImage(withTitle: VectorL10n.userAvatarViewAccessibilityLabel)
        }
    }
}
