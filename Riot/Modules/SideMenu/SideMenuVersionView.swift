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

/// SideMenuVersionView displays application version
final class SideMenuVersionView: UIView, NibOwnerLoadable {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var label: UILabel!
    
    // MARK: Private
    
    private var theme: Theme!
    
    // MARK: Public
        
    // MARK: - Setup
    
    class func instantiate() -> SideMenuVersionView {
        let view = SideMenuVersionView()
        view.theme = ThemeService.shared().theme
        return view
    }
    
    private func commonInit() {
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
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
    
    // MARK: - Public
    
    func fill(with version: String) {
        self.label.text = VectorL10n.sideMenuAppVersion(version)
    }
}

// MARK: - Themable
extension SideMenuVersionView: Themable {
    
    func update(theme: Theme) {
        self.theme = theme
        
        self.label.textColor = theme.textSecondaryColor
    }
}
