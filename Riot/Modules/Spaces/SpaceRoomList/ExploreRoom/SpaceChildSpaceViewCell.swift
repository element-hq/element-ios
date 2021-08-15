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
