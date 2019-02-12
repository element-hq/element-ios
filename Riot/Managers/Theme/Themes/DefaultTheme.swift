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
class DefaultTheme: NSObject, Theme {

    var backgroundColor: UIColor = UIColor(rgb: 0xFFFFFF)

    var baseColor: UIColor = UIColor(rgb: 0x27303A)
    var baseTextPrimaryColor: UIColor = UIColor(rgb: 0xFFFFFF)
    var baseTextSecondaryColor: UIColor = UIColor(rgb: 0xFFFFFF)

    var searchBackgroundColor: UIColor = UIColor(rgb: 0xFFFFFF)
    var searchTextColor: UIColor = UIColor(rgb: 0x61708B)   // Name in the associated palette is Search Placeholder

    var headerBackgroundColor: UIColor = UIColor(rgb: 0xF2F5F8)
    var headerBorderColor: UIColor  = UIColor(rgb: 0xE9EDF1)
    var headerTextPrimaryColor: UIColor = UIColor(rgb: 0x61708B)
    var headerTextSecondaryColor: UIColor = UIColor(rgb: 0xC8C8CD)

    var textPrimaryColor: UIColor = UIColor(rgb: 0x2E2F32)
    var textSecondaryColor: UIColor = UIColor(rgb: 0x9E9E9E)

    var tintColor: UIColor = UIColor(rgb: 0x03B381)
    var unreadRoomIndentColor: UIColor = UIColor(rgb: 0x2E3648)
    
    var notificationSecondaryColor: UIColor = UIColor(rgb: 0x61708B)
    var notificationPrimaryColor: UIColor = UIColor(rgb: 0xFF4B55)

    var warningColor: UIColor = UIColor(rgb: 0xFF4B55)

    var avatarColors: [UIColor] = [
        UIColor(rgb: 0x03B381),
        UIColor(rgb: 0x368BD6),
        UIColor(rgb: 0xAC3BA8)]

    var statusBarStyle: UIStatusBarStyle = .lightContent
    var scrollBarStyle: UIScrollViewIndicatorStyle = .default
    var keyboardAppearance: UIKeyboardAppearance = .light

    var placeholderTextColor: UIColor = UIColor(white: 0.7, alpha: 1.0) // Use default 70% gray color
    var selectedBackgroundColor: UIColor? = nil  // Use the default selection color
    var overlayBackgroundColor: UIColor = UIColor(white: 0.7, alpha: 0.5)
    var matrixSearchBackgroundImageTintColor: UIColor = UIColor(rgb: 0xE7E7E7)
    var separatorColor: UIColor = UIColor(rgb: 0xEAEEF2)

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
        searchBar.barStyle = .default
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
