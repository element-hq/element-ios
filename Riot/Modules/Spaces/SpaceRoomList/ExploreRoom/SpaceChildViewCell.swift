// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import UIKit
import Reusable

class SpaceChildViewCell: UITableViewCell, Themable, NibReusable {

    // MARK: - Properties
    
    @IBOutlet internal weak var avatarView: AvatarView!
    @IBOutlet internal weak var titleLabel: UILabel!
    @IBOutlet internal weak var titleLabelTrailingMargin: NSLayoutConstraint!
    @IBOutlet internal weak var selectionView: UIView!
    @IBOutlet internal weak var userIconView: UIImageView!
    @IBOutlet internal weak var membersLabel: UILabel!
    @IBOutlet internal weak var topicLabel: UILabel!
    @IBOutlet internal weak var suggestedLabel: UILabel!

    // MARK: - Private
    
    private var theme: Theme?
    private var titleLabelDefaultTrailingMargin: CGFloat = 0
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()

        self.selectionView.layer.cornerRadius = 8.0
        self.selectionView.layer.masksToBounds = true
        self.titleLabelDefaultTrailingMargin = self.titleLabelTrailingMargin.constant
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        UIView.animate(withDuration: animated ? 0.3 : 0.0) {
            self.selectionView.alpha = selected ? 1.0 : 0.0
        }
    }

    // MARK: - Public
    
    func fill(with viewData: SpaceExploreRoomListItemViewData) {
        self.avatarView.fill(with: viewData.avatarViewData)
        self.titleLabel.text = viewData.childInfo.name ?? viewData.childInfo.canonicalAlias
        self.membersLabel.text = "\(viewData.childInfo.activeMemberCount)"
        self.topicLabel.text = viewData.childInfo.topic
        self.suggestedLabel.text = viewData.childInfo.suggested ? VectorL10n.spacesSuggestedRoom : nil
        self.titleLabelTrailingMargin.constant = viewData.childInfo.suggested ? self.titleLabelDefaultTrailingMargin : 0
        self.titleLabel.layoutIfNeeded()
    }
    
    func update(theme: Theme) {
        self.theme = theme
        self.backgroundColor = theme.colors.background
        self.avatarView.update(theme: theme)
        self.titleLabel.textColor = theme.colors.primaryContent
        self.titleLabel.font = theme.fonts.calloutSB
        self.selectionView.backgroundColor = theme.colors.separator
        self.membersLabel.font = theme.fonts.caption1
        self.membersLabel.textColor = theme.colors.tertiaryContent
        self.topicLabel.font = theme.fonts.caption1
        self.topicLabel.textColor = theme.colors.tertiaryContent
        self.userIconView.tintColor = theme.colors.tertiaryContent
        self.suggestedLabel.font = theme.fonts.caption2
        self.suggestedLabel.textColor = theme.colors.tertiaryContent
    }
}
