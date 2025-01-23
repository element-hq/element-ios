// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
