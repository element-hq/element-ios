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

    var backgroundColor: UIColor = UIColor(rgb: 0x212224)

    var baseColor: UIColor = UIColor(rgb: 0x292E37)
    var baseTextPrimaryColor: UIColor = UIColor(rgb: 0xFFFFFF)
    var baseTextSecondaryColor: UIColor = UIColor(rgb: 0xFFFFFF)

    var searchBackgroundColor: UIColor = UIColor(rgb: 0x3E434B)
    var searchTextColor: UIColor = UIColor(rgb: 0xACB3C2)

    var headerBackgroundColor: UIColor = UIColor(rgb: 0x303540)
    var headerBorderColor: UIColor  = UIColor(rgb: 0x2E2F31)
    var headerTextPrimaryColor: UIColor = UIColor(rgb: 0x96A1B7)
    var headerTextSecondaryColor: UIColor = UIColor(rgb: 0xC8C8CD)

    var textPrimaryColor: UIColor = UIColor(rgb: 0xFFFFFF)
    var textSecondaryColor: UIColor = UIColor(rgb: 0xD8D8D8)

    var tintColor: UIColor = UIColor(rgb: 0x7AC9A1)
    var unreadRoomIndentColor: UIColor = UIColor(rgb: 0x2E3648)
    
    var notificationSecondaryColor: UIColor = UIColor(rgb: 0x7AC9A1)
    var notificationPrimaryColor: UIColor = UIColor(rgb: 0xF56679)

    var warningColor: UIColor = UIColor(rgb: 0xF56679)

    var avatarColors: [UIColor] = [
        UIColor(rgb: 0x7AC9A1),
        UIColor(rgb: 0x1E7DDC),
        UIColor(rgb: 0x76DDD7)]

    var statusBarStyle: UIStatusBarStyle = .lightContent
    var scrollBarStyle: UIScrollViewIndicatorStyle = .white
    var keyboardAppearance: UIKeyboardAppearance = .dark

    var placeholderTextColor: UIColor = UIColor(white: 1.0, alpha: 0.3)
    var selectedBackgroundColor: UIColor? = UIColor.black
    var overlayBackgroundColor: UIColor = UIColor(white: 0.7, alpha: 0.5)
    var matrixSearchBackgroundImageTintColor: UIColor = UIColor(rgb: 0x7E7E7E)
    var separatorColor: UIColor = UIColor(rgb: 0x2E2F31)

    func applyStyle(onNavigationBar navigationBar: UINavigationBar) {
        navigationBar.tintColor = self.baseTextPrimaryColor;
        navigationBar.titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: self.baseTextPrimaryColor
        ]
        navigationBar.barTintColor = self.baseColor;

        // The navigation bar needs to be opaque so that its background color is the expected one
        navigationBar.isTranslucent = false;
    }

    func applyStyle(onSearchBar searchBar: UISearchBar) {
        searchBar.barStyle = .black
        searchBar.tintColor = self.searchTextColor;
        searchBar.barTintColor = self.headerBackgroundColor;
        searchBar.layer.borderWidth = 1;
        searchBar.layer.borderColor = self.headerBorderColor.cgColor;
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
