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
