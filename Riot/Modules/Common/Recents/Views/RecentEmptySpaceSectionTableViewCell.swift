// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import Reusable

/// `RecentEmptySpaceSectionTableViewCell` can be used as a placeholder for empty space sections.
class RecentEmptySpaceSectionTableViewCell: UITableViewCell, NibReusable, Themable {
    
    @IBOutlet var iconView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    
    @objc static func defaultReuseIdentifier() -> String {
        return reuseIdentifier
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()

        self.selectionStyle = .none
        
        update(theme: ThemeService.shared().theme)
    }

    // MARK: - Themable
    
    func update(theme: Theme) {
        self.backgroundColor = theme.colors.background
        
        self.iconView.tintColor = theme.colors.secondaryContent
        
        self.titleLabel.textColor = theme.colors.primaryContent
        self.titleLabel.font = theme.fonts.title3SB
        
        self.messageLabel.textColor = theme.colors.secondaryContent
        self.messageLabel.font = theme.fonts.callout
    }
}
