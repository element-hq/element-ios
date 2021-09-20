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
        self.moreButton.isHidden = viewData.spaceId == SpaceListViewModel.Constants.homeSpaceId || viewData.isInvite
        if viewData.isInvite {
            self.badgeLabel.isHidden = false
            self.badgeLabel.badgeColor = ThemeService.shared().theme.colors.alert
            self.badgeLabel.text = "!"
        } else {
            let notificationCount = viewData.notificationCount + viewData.highlightedNotificationCount
            self.badgeLabel.isHidden = notificationCount == 0
            self.badgeLabel.badgeColor = viewData.highlightedNotificationCount == 0 ? ThemeService.shared().theme.colors.tertiaryContent : ThemeService.shared().theme.colors.alert
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
        self.badgeLabel.borderColor = ThemeService.shared().theme.colors.background
    }
    
    // MARK: - IBActions
    
    @IBAction private func moreAction(sender: UIButton) {
        delegate?.spaceListViewCell(self, didPressMore: self.moreButton)
    }
}
