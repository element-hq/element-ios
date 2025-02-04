// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import Reusable

class SpaceChildSpaceViewCell: SpaceChildViewCell {
    
    @IBOutlet private weak var roomsIcon: UIImageView!
    @IBOutlet private weak var roomNumberLabel: UILabel!
    @IBOutlet private weak var spaceTagView: UIView!

    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.spaceTagView.layer.masksToBounds = true
        self.spaceTagView.layer.cornerRadius = 2
    }

    // MARK: - Public
    
    override func fill(with viewData: SpaceExploreRoomListItemViewData) {
        super.fill(with: viewData)
        
        self.roomNumberLabel.text = "\(viewData.childInfo.childrenIds.count)"
        self.topicLabel.text = VectorL10n.spaceTag
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)
        
        self.roomNumberLabel.font = theme.fonts.caption1
        self.roomNumberLabel.textColor = theme.colors.tertiaryContent
        self.roomsIcon.tintColor = theme.colors.tertiaryContent
        self.spaceTagView.backgroundColor = theme.colors.quinaryContent
    }
}
