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

import UIKit
import Reusable

/// `RecentsInvitesTableViewCell` can be used as a placeholder to show invites number
class RecentsInvitesTableViewCell: UITableViewCell, NibReusable, Themable {
    
    // MARK: - Outlet
    
    @IBOutlet weak private var badgeLabel: BadgeLabel!
    @IBOutlet weak private var titleLabel: UILabel!
    
    // MARK: - Properties
    
    @objc var invitesCount: Int = 0 {
        didSet {
            badgeLabel.text = "\(invitesCount)"
        }
    }
    
    // MARK: - NibReusable
    
    @objc static func defaultReuseIdentifier() -> String {
        return reuseIdentifier
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()

        setupView()
        update(theme: ThemeService.shared().theme)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        update(theme: ThemeService.shared().theme)
    }
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        self.backgroundColor = theme.colors.background
        
        badgeLabel.badgeColor = theme.colors.alert
        badgeLabel.textColor = theme.colors.background
        badgeLabel.font = theme.fonts.footnoteSB
        
        titleLabel.textColor = theme.colors.accent
    }
    
    // MARK: - Private
    
    private func setupView() {
        self.selectionStyle = .none
        
        titleLabel.text = VectorL10n.roomRecentsInvitesSection.capitalized
        update(theme: ThemeService.shared().theme)
    }
}
