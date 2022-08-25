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

class SpaceChildViewCell: UITableViewCell, Themable, NibReusable {
    // MARK: - Properties
    
    @IBOutlet internal var avatarView: AvatarView!
    @IBOutlet internal var titleLabel: UILabel!
    @IBOutlet internal var titleLabelTrailingMargin: NSLayoutConstraint!
    @IBOutlet internal var selectionView: UIView!
    @IBOutlet internal var userIconView: UIImageView!
    @IBOutlet internal var membersLabel: UILabel!
    @IBOutlet internal var topicLabel: UILabel!
    @IBOutlet internal var suggestedLabel: UILabel!

    // MARK: - Private
    
    private var theme: Theme?
    private var titleLabelDefaultTrailingMargin: CGFloat = 0
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()

        selectionView.layer.cornerRadius = 8.0
        selectionView.layer.masksToBounds = true
        titleLabelDefaultTrailingMargin = titleLabelTrailingMargin.constant
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        UIView.animate(withDuration: animated ? 0.3 : 0.0) {
            self.selectionView.alpha = selected ? 1.0 : 0.0
        }
    }

    // MARK: - Public
    
    func fill(with viewData: SpaceExploreRoomListItemViewData) {
        avatarView.fill(with: viewData.avatarViewData)
        titleLabel.text = viewData.childInfo.name ?? viewData.childInfo.canonicalAlias
        membersLabel.text = "\(viewData.childInfo.activeMemberCount)"
        topicLabel.text = viewData.childInfo.topic
        suggestedLabel.text = viewData.childInfo.suggested ? VectorL10n.spacesSuggestedRoom : nil
        titleLabelTrailingMargin.constant = viewData.childInfo.suggested ? titleLabelDefaultTrailingMargin : 0
        titleLabel.layoutIfNeeded()
    }
    
    func update(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.background
        avatarView.update(theme: theme)
        titleLabel.textColor = theme.colors.primaryContent
        titleLabel.font = theme.fonts.calloutSB
        selectionView.backgroundColor = theme.colors.separator
        membersLabel.font = theme.fonts.caption1
        membersLabel.textColor = theme.colors.tertiaryContent
        topicLabel.font = theme.fonts.caption1
        topicLabel.textColor = theme.colors.tertiaryContent
        userIconView.tintColor = theme.colors.tertiaryContent
        suggestedLabel.font = theme.fonts.caption2
        suggestedLabel.textColor = theme.colors.tertiaryContent
    }
}
