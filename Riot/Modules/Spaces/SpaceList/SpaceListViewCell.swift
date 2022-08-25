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

import Reusable
import UIKit

protocol SpaceListViewCellDelegate: AnyObject {
    func spaceListViewCell(_ cell: SpaceListViewCell, didPressMore button: UIButton)
}

final class SpaceListViewCell: UITableViewCell, Themable, NibReusable {
    // MARK: - Properties
    
    @IBOutlet private var avatarView: SpaceAvatarView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var selectionView: UIView!
    @IBOutlet private var moreButton: UIButton!
    @IBOutlet private var badgeLabel: BadgeLabel!
    
    public weak var delegate: SpaceListViewCellDelegate?
    
    private var theme: Theme?
    private var isBadgeAlert = false
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()

        selectionView.layer.cornerRadius = 8.0
        selectionView.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        UIView.animate(withDuration: animated ? 0.3 : 0.0) {
            self.selectionView.alpha = selected ? 1.0 : 0.0
        }
    }

    // MARK: - Public
    
    func fill(with viewData: SpaceListItemViewData) {
        avatarView.fill(with: viewData.avatarViewData)
        titleLabel.text = viewData.title
        moreButton.isHidden = viewData.spaceId == SpaceListViewModel.Constants.addSpaceId || viewData.isInvite
        if viewData.isInvite {
            isBadgeAlert = true
            badgeLabel.isHidden = false
            if let theme = theme {
                badgeLabel.badgeColor = theme.colors.alert
            }
            badgeLabel.text = "!"
        } else {
            isBadgeAlert = viewData.highlightedNotificationCount > 0
            let notificationCount = viewData.notificationCount
            badgeLabel.isHidden = notificationCount == 0
            if let theme = theme {
                badgeLabel.badgeColor = viewData.highlightedNotificationCount == 0 ? theme.colors.tertiaryContent : theme.colors.alert
            }
            badgeLabel.text = "\(notificationCount)"
        }
    }
    
    func update(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.background
        avatarView.update(theme: theme)
        titleLabel.textColor = theme.colors.primaryContent
        titleLabel.font = theme.fonts.calloutSB
        selectionView.backgroundColor = theme.colors.separator
        moreButton.tintColor = theme.colors.secondaryContent
        badgeLabel.borderColor = theme.colors.background
        badgeLabel.badgeColor = isBadgeAlert ? theme.colors.alert : theme.colors.tertiaryContent
    }
    
    // MARK: - IBActions
    
    @IBAction private func moreAction(sender: UIButton) {
        delegate?.spaceListViewCell(self, didPressMore: moreButton)
    }
}
