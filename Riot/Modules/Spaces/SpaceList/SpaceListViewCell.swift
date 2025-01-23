// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import Reusable

protocol SpaceListViewCellDelegate: AnyObject {
    func spaceListViewCell(_ cell: SpaceListViewCell, didPressMore button: UIButton)
}

final class SpaceListViewCell: UITableViewCell, Themable, NibReusable {

    // MARK: - Properties
    
    @IBOutlet private weak var avatarView: SpaceAvatarView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var selectionView: UIView!
    @IBOutlet private weak var moreButton: UIButton!
    @IBOutlet private weak var badgeLabel: BadgeLabel!
    
    public weak var delegate: SpaceListViewCellDelegate?
    
    private var theme: Theme?
    private var isBadgeAlert: Bool = false
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()

        self.selectionView.layer.cornerRadius = 8.0
        self.selectionView.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        UIView.animate(withDuration: animated ? 0.3 : 0.0) {
            self.selectionView.alpha = selected ? 1.0 : 0.0
        }
    }

    // MARK: - Public
    
    func fill(with viewData: SpaceListItemViewData) {
        self.avatarView.fill(with: viewData.avatarViewData)
        self.titleLabel.text = viewData.title
        self.moreButton.isHidden = viewData.spaceId == SpaceListViewModel.Constants.addSpaceId || viewData.isInvite
        if viewData.isInvite {
            self.isBadgeAlert = true
            self.badgeLabel.isHidden = false
            if let theme = self.theme {
                self.badgeLabel.badgeColor = theme.colors.alert
            }
            self.badgeLabel.text = "!"
        } else {
            self.isBadgeAlert = viewData.highlightedNotificationCount > 0
            let notificationCount = viewData.notificationCount
            self.badgeLabel.isHidden = notificationCount == 0
            if let theme = self.theme {
                self.badgeLabel.badgeColor = viewData.highlightedNotificationCount == 0 ? theme.colors.tertiaryContent : theme.colors.alert
            }
            self.badgeLabel.text = "\(notificationCount)"
        }
    }
    
    func update(theme: Theme) {
        self.theme = theme
        self.backgroundColor = theme.colors.background
        self.avatarView.update(theme: theme)
        self.titleLabel.textColor = theme.colors.primaryContent
        self.titleLabel.font = theme.fonts.calloutSB
        self.selectionView.backgroundColor = theme.colors.separator
        self.moreButton.tintColor = theme.colors.secondaryContent
        self.badgeLabel.borderColor = theme.colors.background
        self.badgeLabel.badgeColor = self.isBadgeAlert ? theme.colors.alert : theme.colors.tertiaryContent
    }
    
    // MARK: - IBActions
    
    @IBAction private func moreAction(sender: UIButton) {
        delegate?.spaceListViewCell(self, didPressMore: self.moreButton)
    }
}
