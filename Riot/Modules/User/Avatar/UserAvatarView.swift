//
// Copyright 2021 New Vector Ltd
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

import Reusable
import UIKit

final class UserAvatarView: AvatarView {
    // MARK: - Setup
    
    private func commonInit() {
        let avatarImageView = MXKImageView()
        vc_addSubViewMatchingParent(avatarImageView)
        self.avatarImageView = avatarImageView
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    // MARK: - Overrides
    
    override func updateAccessibilityTraits() {
        if isUserInteractionEnabled {
            vc_setupAccessibilityTraitsButton(withTitle: VectorL10n.userAvatarViewAccessibilityLabel, hint: VectorL10n.userAvatarViewAccessibilityHint, isEnabled: true)
        } else {
            vc_setupAccessibilityTraitsImage(withTitle: VectorL10n.userAvatarViewAccessibilityLabel)
        }
    }
}
