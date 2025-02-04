// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

class TitleAndRightDetailTableViewCell: MXKTableViewCell {
    
    // MARK: Outlet
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var detailLabel: UILabel!
    
    // MARK: Properties
    
    override var isUserInteractionEnabled: Bool {
        didSet {
            titleLabel.alpha = isUserInteractionEnabled ? 1 : 0.3
            detailLabel.alpha = isUserInteractionEnabled ? 1 : 0.3
        }
    }

    // MARK: - MXKTableViewCell
    
    override func customizeRendering() {
        super.customizeRendering()
        
        let theme = ThemeService.shared().theme
        
        titleLabel.textColor = theme.colors.primaryContent
        titleLabel.font = theme.fonts.body
        
        detailLabel.textColor = theme.colors.secondaryContent
        detailLabel.font = theme.fonts.body
    }
}
