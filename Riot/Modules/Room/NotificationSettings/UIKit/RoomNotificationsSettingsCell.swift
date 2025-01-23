// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//
import UIKit
import Reusable

class RoomNotificationSettingsCell: UITableViewCell {
    
    func update(state: RoomNotificationSettingsCellViewData) {
        textLabel?.text = state.notificicationState.title
        if state.selected {
            accessoryView = UIImageView(image: Asset.Images.checkmark.image)
        } else {
            accessoryView = nil
        }
    }
}

extension RoomNotificationSettingsCell: Reusable {}

extension RoomNotificationSettingsCell: Themable {
    func update(theme: Theme) {
        textLabel?.font = theme.fonts.body
        textLabel?.textColor = theme.textPrimaryColor
        backgroundColor = theme.backgroundColor
        contentView.backgroundColor = .clear
        tintColor = theme.tintColor
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = theme.selectedBackgroundColor
    }
}
