// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
