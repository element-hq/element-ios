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

import Foundation
import Reusable

class RoomNotificationSettingsAvatarView: UIView {
    
    @IBOutlet weak var avatarView: RoomAvatarView!
    @IBOutlet weak var nameLabel: UILabel!
    
    func configure(viewData: AvatarViewDataProtocol) {
        avatarView.fill(with: viewData)
        
        switch viewData.fallbackImages?.first {
        case .matrixItem(_, let matrixItemDisplayName):
            nameLabel.text = matrixItemDisplayName
        default:
            nameLabel.text = nil
        }
    }
}

extension RoomNotificationSettingsAvatarView: NibLoadable { }
extension RoomNotificationSettingsAvatarView: Themable {
    func update(theme: Theme) {
        nameLabel?.font = theme.fonts.title3SB
        nameLabel?.textColor = theme.textPrimaryColor
    }
}
