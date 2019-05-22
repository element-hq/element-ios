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

/// Color constants for the dark theme
@objcMembers
class DarkTheme: NSObject, Theme {

    var backgroundColor: UIColor = UIColor(rgb: 0x181B21)

    var baseColor: UIColor = UIColor(rgb: 0x15171B)
    var baseTextPrimaryColor: UIColor = UIColor(rgb: 0xEDF3FF)
    var baseTextSecondaryColor: UIColor = UIColor(rgb: 0xEDF3FF)

    var searchBackgroundColor: UIColor = UIColor(rgb: 0x181B21)
    var searchPlaceholderColor: UIColor = UIColor(rgb: 0x61708B)

    var headerBackgroundColor: UIColor = UIColor(rgb: 0x22262E)
    var headerBorderColor: UIColor  = UIColor(rgb: 0x181B21)
    var headerTextPrimaryColor: UIColor = UIColor(rgb: 0xA1B2D1)
    var headerTextSecondaryColor: UIColor = UIColor(rgb: 0xC8C8CD)

    var textPrimaryColor: UIColor = UIColor(rgb: 0xEDF3FF)
    var textSecondaryColor: UIColor = UIColor(rgb: 0xA1B2D1)

    var tintColor: UIColor = UIColor(rgb: 0x03B381)
    var tintBackgroundColor: UIColor = UIColor(rgb: 0x1F6954)
    var unreadRoomIndentColor: UIColor = UIColor(rgb: 0x2E3648)
    var lineBreakColor: UIColor = UIColor(rgb: 0x61708B)
    
    var noticeColor: UIColor = UIColor(rgb: 0xFF4B55)
    var noticeSecondaryColor: UIColor = UIColor(rgb: 0x61708B)

    var warningColor: UIColor = UIColor(rgb: 0xFF4B55)

    var avatarColors: [UIColor] = [
        UIColor(rgb: 0x03B381),
        UIColor(rgb: 0x368BD6),
        UIColor(rgb: 0xAC3BA8)]
    
    var userNameColors: [UIColor] = [
        UIColor(rgb: 0x368BD6),
        UIColor(rgb: 0xAC3BA8),
        UIColor(rgb: 0x03B381),
        UIColor(rgb: 0xE64F7A),
        UIColor(rgb: 0xFF812D),
        UIColor(rgb: 0x2DC2C5),
        UIColor(rgb: 0x5C56F5),
        UIColor(rgb: 0x74D12C)
    ]

    var statusBarStyle: UIStatusBarStyle = .lightContent
    var scrollBarStyle: UIScrollView.IndicatorStyle = .white
    var keyboardAppearance: UIKeyboardAppearance = .dark

    var placeholderTextColor: UIColor = UIColor(white: 1.0, alpha: 0.3)
    var selectedBackgroundColor: UIColor? = UIColor.black
    var overlayBackgroundColor: UIColor = UIColor(white: 0.7, alpha: 0.5)
    var matrixSearchBackgroundImageTintColor: UIColor = UIColor(rgb: 0x7E7E7E)
    
    func applyStyle(onTabBar tabBar: UITabBar) {
        tabBar.tintColor = self.tintColor
        tabBar.barTintColor = self.headerBackgroundColor
        tabBar.isTranslucent = false
    }

    func applyStyle(onNavigationBar navigationBar: UINavigationBar) {
        navigationBar.tintColor = self.baseTextPrimaryColor
        navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: self.baseTextPrimaryColor
        ]
        navigationBar.barTintColor = self.baseColor

        // The navigation bar needs to be opaque so that its background color is the expected one
        navigationBar.isTranslucent = false
    }

    func applyStyle(onSearchBar searchBar: UISearchBar) {
        searchBar.barStyle = .black
        searchBar.tintColor = self.searchPlaceholderColor
        searchBar.barTintColor = self.headerBackgroundColor        
    }
    
    func applyStyle(onTextField texField: UITextField) {
        texField.textColor = self.textPrimaryColor
        texField.tintColor = self.tintColor
    }
    
    func applyStyle(onButton button: UIButton) {
        // NOTE: Tint color does nothing by default on button type `UIButtonType.custom`
        button.tintColor = self.tintColor
    }
}
