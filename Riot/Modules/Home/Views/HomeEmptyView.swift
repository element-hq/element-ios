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

import Foundation
import Reusable

@objcMembers
final class HomeEmptyView: UIView, NibLoadable {
    
    // MARK: - Properties
    
    // MARK: Outlets
        
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    
    // MARK: Private
    
    private var theme: Theme!
    
    // MARK: Public
    
    // MARK: - Setup
    
    class func instantiate() -> HomeEmptyView {
        let view = HomeEmptyView.loadFromNib()
        view.theme = ThemeService.shared().theme
        return view
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.informationLabel.text = VectorL10n.homeEmptyViewInformation
    }
    
    // MARK: - Public
    
    func fill(with displayName: String) {
        self.titleLabel.text = VectorL10n.homeEmptyViewTitle(displayName)
    }
}

// MARK: - Themable
extension HomeEmptyView: Themable {
    
    func update(theme: Theme) {
        self.theme = theme
        
        self.backgroundColor = theme.backgroundColor
        
        self.titleLabel.textColor = theme.textPrimaryColor
        self.informationLabel.textColor = theme.textSecondaryColor
    }
}
