// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
