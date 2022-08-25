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

class SpaceChildSpaceViewCell: SpaceChildViewCell {
    @IBOutlet private var roomsIcon: UIImageView!
    @IBOutlet private var roomNumberLabel: UILabel!
    @IBOutlet private var spaceTagView: UIView!

    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        spaceTagView.layer.masksToBounds = true
        spaceTagView.layer.cornerRadius = 2
    }

    // MARK: - Public
    
    override func fill(with viewData: SpaceExploreRoomListItemViewData) {
        super.fill(with: viewData)
        
        roomNumberLabel.text = "\(viewData.childInfo.childrenIds.count)"
        topicLabel.text = VectorL10n.spaceTag
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)
        
        roomNumberLabel.font = theme.fonts.caption1
        roomNumberLabel.textColor = theme.colors.tertiaryContent
        roomsIcon.tintColor = theme.colors.tertiaryContent
        spaceTagView.backgroundColor = theme.colors.quinaryContent
    }
}
