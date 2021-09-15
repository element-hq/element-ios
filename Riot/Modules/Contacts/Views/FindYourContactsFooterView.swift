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

import UIKit
import Reusable

@objc protocol FindYourContactsFooterViewDelegate {
    func didTapEnableContactsSync()
}

@objcMembers
class FindYourContactsFooterView: UIView, NibLoadable, Themable {
    
    // MARK: - Properties
    
    weak var delegate: FindYourContactsFooterViewDelegate?
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var button: CustomRoundedButton!
    @IBOutlet weak var footerLabel: UILabel!
    
    // MARK: - Setup
    
    static func instantiate() -> Self {
        let view = Self.loadFromNib()
        view.update(theme: ThemeService.shared().theme)
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.cornerRadius = 8
        button.layer.cornerRadius = 8
        
        titleLabel.text = VectorL10n.findYourContactsTitle
        messageLabel.text = VectorL10n.findYourContactsMessage(BuildSettings.bundleDisplayName)
        button.setTitle(VectorL10n.findYourContactsButtonTitle, for: .normal)
        footerLabel.text = VectorL10n.findYourContactsFooter
    }
    
    func update(theme: Theme) {
        tintColor = theme.colors.accent
        
        containerView.backgroundColor = theme.colors.quinaryContent
        
        titleLabel.font = theme.fonts.bodySB
        titleLabel.textColor = theme.colors.primaryContent
        
        messageLabel.font = theme.fonts.body
        messageLabel.textColor = theme.colors.secondaryContent
        
        button.titleLabel?.font = theme.fonts.body
        button.backgroundColor = theme.colors.accent
        button.setTitleColor(theme.colors.background, for: .normal)
        
        footerLabel.font = theme.fonts.footnote.withSize(13)
        footerLabel.textColor = theme.colors.tertiaryContent
    }
    
    // MARK: - Action
    
    @IBAction private func enableContactsSync(_ sender: Any) {
        delegate?.didTapEnableContactsSync()
    }
}
