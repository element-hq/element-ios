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

protocol ServiceTermsModalTableHeaderViewDelegate: AnyObject {
    func tableHeaderViewDidTapInformationButton()
}

class ServiceTermsModalTableHeaderView: UIView, NibLoadable, Themable {
    
    // MARK: - Properties
    
    weak var delegate: ServiceTermsModalTableHeaderViewDelegate?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var serviceURLLabel: UILabel!
    
    // MARK: - Setup
    
    static func instantiate() -> Self {
        let view = Self.loadFromNib()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.update(theme: ThemeService.shared().theme)
        return view
    }
    
    func update(theme: Theme) {
        titleLabel.font = theme.fonts.footnote
        titleLabel.textColor = theme.colors.secondaryContent
        
        serviceURLLabel.font = theme.fonts.callout
        serviceURLLabel.textColor = theme.colors.secondaryContent
    }
    
    // MARK: - Action
    
    @IBAction private func buttonAction(_ sender: Any) {
        delegate?.tableHeaderViewDidTapInformationButton()
    }
    
}
