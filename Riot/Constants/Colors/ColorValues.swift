/*
 Copyright 2018 New Vector Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit

/// Provide color constant values defined by the designer
/// https://app.zeplin.io/project/5b857c64b1747a2c472290da/screen/5bf2cc89a4a6973f47883c6e
@objc protocol ColorValues {

    var background: UIColor { get }
    var base: UIColor { get }

    var baseTextPrimary: UIColor { get }
    var baseTextSecondary: UIColor { get }

    var searchBackground: UIColor { get }
    var searchText: UIColor { get }

    var headerBackground: UIColor { get }
    var headerBorder: UIColor { get }
    var headerTextPrimary: UIColor { get }
    var headerTextSecondary: UIColor { get }

    var textPrimary: UIColor { get }
    var textSecondary: UIColor { get }

    var accent: UIColor { get }
    var unreadRoomIndent: UIColor { get }
    
    var notificationUnread: UIColor { get }
    var notificationMention: UIColor { get }

    var avatars: [UIColor] { get }
}

extension UIColor {
    convenience init(rgb: UInt) {
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
