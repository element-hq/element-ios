// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
