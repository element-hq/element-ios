//
// Copyright 2022 New Vector Ltd
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

import Reusable
import UIKit

/// `RecentEmptySectionTableViewCell` can be used as a placeholder for empty sections.
class RecentEmptySectionTableViewCell: UITableViewCell, NibReusable, Themable {
    @IBOutlet private var iconBackgroundView: UIView!
    @IBOutlet var iconView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    
    @objc static func defaultReuseIdentifier() -> String {
        reuseIdentifier
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()

        iconBackgroundView.layer.cornerRadius = iconBackgroundView.bounds.height / 2
        iconBackgroundView.layer.masksToBounds = true
        
        selectionStyle = .none
        
        update(theme: ThemeService.shared().theme)
    }

    // MARK: - Themable
    
    func update(theme: Theme) {
        backgroundColor = theme.colors.background
        
        iconBackgroundView.backgroundColor = theme.colors.quinaryContent
        iconView.tintColor = theme.colors.secondaryContent
        
        titleLabel.textColor = theme.colors.primaryContent
        titleLabel.font = theme.fonts.title3SB
        
        messageLabel.textColor = theme.colors.secondaryContent
        messageLabel.font = theme.fonts.callout
    }
}
