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

@objc protocol RequestContactsAccessFooterViewDelegate {
    func didRequestContactsAccess()
}

@objcMembers
class RequestContactsAccessFooterView: UIView, NibLoadable, Themable {
    
    weak var delegate: RequestContactsAccessFooterViewDelegate?
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var requestAccessButton: CustomRoundedButton!
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
        requestAccessButton.layer.cornerRadius = 8
    }
    
    func update(theme: Theme) {
        tintColor = theme.tintColor
        
        containerView.backgroundColor = theme.textQuinaryColor
        
        titleLabel.textColor = theme.textPrimaryColor
        descriptionLabel.textColor = theme.textSecondaryColor
        footerLabel.textColor = theme.textTertiaryColor
        
        requestAccessButton.backgroundColor = theme.tintColor
        requestAccessButton.setTitleColor(theme.backgroundColor, for: .normal)
    }
    
    @IBAction private func requestContactsAccess(_ sender: Any) {
        delegate?.didRequestContactsAccess()
    }
}
