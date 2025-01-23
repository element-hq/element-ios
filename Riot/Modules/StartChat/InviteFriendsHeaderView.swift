// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import Reusable

@objc
protocol InviteFriendsHeaderViewDelegate: AnyObject {
    func inviteFriendsHeaderView(_ headerView: InviteFriendsHeaderView, didTapButton button: UIButton)
}

@objcMembers
final class InviteFriendsHeaderView: UIView, NibLoadable, Themable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let buttonHighlightedAlpha: CGFloat = 0.2
    }
    
    // MARK: - Properties
    
    @IBOutlet private weak var button: CustomRoundedButton!
    
    weak var delegate: InviteFriendsHeaderViewDelegate?
    
    // MARK: - Setup
    
    static func instantiate() -> InviteFriendsHeaderView {
        let view = InviteFriendsHeaderView.loadFromNib()
        view.update(theme: ThemeService.shared().theme)
        return view
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        button.setTitle(VectorL10n.inviteFriendsAction(AppInfo.current.displayName), for: .normal)
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
        delegate?.inviteFriendsHeaderView(self, didTapButton: button)
    }
}
