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

class RoomNotificationSettingsFooter: UITableViewHeaderFooterView {
    
    struct State {
        let showEncryptedNotice: Bool
        let showAccountLink: Bool
    }
    
    @IBOutlet weak var label: UILabel!
    
    func update(footerState: State) {
        
        // Don't include link until global settings in place
//        let paragraphStyle = NSMutableParagraphStyle()
//        paragraphStyle.lineHeightMultiple = 1.16
//        let paragraphAttributes: [NSAttributedString.Key: Any] = [
//            NSAttributedString.Key.kern: -0.08,
//            NSAttributedString.Key.paragraphStyle: paragraphStyle,
//            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0)
//        ]
//        let linkStr = VectorL10n.roomNotifsSettingsAccountSettings
//        let formatStr = VectorL10n.roomNotifsSettingsManageNotifications(linkStr)
//
//        let formattedStr = String(format: formatStr, arguments: [linkStr])
//        let footer0 = NSMutableAttributedString(string: formattedStr, attributes: paragraphAttributes)
//        let linkRange = (footer0.string as NSString).range(of: linkStr)
//        footer0.addAttribute(NSAttributedString.Key.link, value: Constants.linkToAccountSettings, range: linkRange)
        
        label.text = footerState.showEncryptedNotice ? VectorL10n.roomNotifsSettingsEncryptedRoomNotice : nil

    }
}


extension RoomNotificationSettingsFooter: NibReusable {}
extension RoomNotificationSettingsFooter: Themable {
    
    func update(theme: Theme) {
        contentView.backgroundColor = theme.headerBackgroundColor
        label.textColor = theme.headerTextSecondaryColor
    }
}
