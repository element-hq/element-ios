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

import Foundation
import Reusable

final class SpaceAvatarView: AvatarView, NibOwnerLoadable {
    // MARK: - Constants
    
    private enum Constants {
        static let cornerRadius: CGFloat = 8.0
    }
    
    // MARK: - Properties

    // MARK: Outlets
    
    @IBOutlet private var cameraBadgeContainerView: UIView!
    
    // MARK: Public
    
    var showCameraBadgeOnFallbackImage = false
    
    // MARK: - Setup
    
    private func commonInit() { }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNibContent()
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNibContent()
        commonInit()
    }
    
    // MARK: - Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        avatarImageView.layer.cornerRadius = Constants.cornerRadius
    }
    
    // MARK: - Public
    
    override func fill(with viewData: AvatarViewDataProtocol) {
        updateAvatarImageView(with: viewData)

        // Fix layoutSubviews not triggered issue
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setNeedsLayout()
        }
    }
    
    // MARK: - Overrides
    
    override func updateAccessibilityTraits() {
        if isUserInteractionEnabled {
            vc_setupAccessibilityTraitsButton(withTitle: VectorL10n.spaceAvatarViewAccessibilityLabel, hint: VectorL10n.spaceAvatarViewAccessibilityHint, isEnabled: true)
        } else {
            vc_setupAccessibilityTraitsImage(withTitle: VectorL10n.spaceAvatarViewAccessibilityLabel)
        }
    }
    
    override func updateAvatarImageView(with viewData: AvatarViewDataProtocol) {
        super.updateAvatarImageView(with: viewData)
        
        let hideCameraBadge: Bool
        
        if showCameraBadgeOnFallbackImage {
            hideCameraBadge = viewData.avatarUrl != nil
        } else {
            hideCameraBadge = true
        }
        
        cameraBadgeContainerView.isHidden = hideCameraBadge
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)
        
        avatarImageView.defaultBackgroundColor = theme.colors.tile
    }
}
