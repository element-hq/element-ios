// 
// Copyright 2020 New Vector Ltd
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
import Reusable

@objc
protocol ShareInviteLinkHeaderViewDelegate: AnyObject {
    func shareInviteLinkHeaderView(_ headerView: ShareInviteLinkHeaderView, didTapButton button: UIButton)
}

@objcMembers
final class ShareInviteLinkHeaderView: UIView, NibLoadable, Themable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let buttonHighlightedAlpha: CGFloat = 0.2
    }
    
    // MARK: - Properties
    
    @IBOutlet private weak var button: CustomRoundedButton!
    
    weak var delegate: ShareInviteLinkHeaderViewDelegate?
    
    // MARK: - Setup
    
    static func instantiate() -> ShareInviteLinkHeaderView {
        let view = ShareInviteLinkHeaderView.loadFromNib()
        view.update(theme: ThemeService.shared().theme)
        return view
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        button.setTitle(VectorL10n.shareInviteLinkAction, for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 2
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        button.layer.borderColor = theme.tintColor.cgColor
        button.setTitleColor(theme.tintColor, for: .normal)
        button.setTitleColor(theme.tintColor.withAlphaComponent(Constants.buttonHighlightedAlpha), for: .highlighted)
        button.vc_setBackgroundColor(theme.baseColor, for: .normal)
        
        let buttonImage = Asset.Images.shareActionButton.image.vc_tintedImage(usingColor: theme.tintColor)
        
        button.setImage(buttonImage, for: .normal)
    }
    
    // MARK: - Action
    
    @objc private func buttonAction(_ sender: UIButton) {
        delegate?.shareInviteLinkHeaderView(self, didTapButton: button)
    }
}
