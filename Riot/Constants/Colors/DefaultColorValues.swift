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

import Foundation
import UIKit

/// Color constants for the default theme
@objcMembers
final class DefaultColorValues: NSObject, ColorValues {

    static let shared = DefaultColorValues()

    let background: UIColor = UIColor(rgb: 0xFFFFFF)

    let base: UIColor = UIColor(rgb: 0x2E3648)
    let baseTextPrimary: UIColor = UIColor(rgb: 0xFFFFFF)
    let baseTextSecondary: UIColor = UIColor(rgb: 0xFFFFFF)

    let searchBackground: UIColor = UIColor(rgb: 0xFFFFFF)
    let searchText: UIColor = UIColor(rgb: 0xACB3C2)

    let headerBackground: UIColor = UIColor(rgb: 0xF1F5F8)
    let headerBorder: UIColor  = UIColor(rgb: 0xEAEEF2)
    let headerTextPrimary: UIColor = UIColor(rgb: 0x96A1B7)
    let headerTextSecondary: UIColor = UIColor(rgb: 0xC8C8CD)

    let textPrimary: UIColor = UIColor(rgb: 0x383838)
    let textSecondary: UIColor = UIColor(rgb: 0x9E9E9E)

    let accent: UIColor = UIColor(rgb: 0x7AC9A1)
    let unreadRoomIndent: UIColor = UIColor(rgb: 0x2E3648)
    
    let notificationUnread: UIColor = UIColor(rgb: 0x7AC9A1)
    let notificationMention: UIColor = UIColor(rgb: 0xF56679)

    let avatars: [UIColor] = [
        UIColor(rgb: 0x7AC9A1),
        UIColor(rgb: 0x1E7DDC),
        UIColor(rgb: 0x76DDD7)]
}
