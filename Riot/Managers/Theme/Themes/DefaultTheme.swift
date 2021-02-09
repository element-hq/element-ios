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

    var identifier: String = ThemeIdentifier.light.rawValue
    
    var backgroundColor: UIColor = UIColor(rgb: 0xFFFFFF)

    var baseColor: UIColor = UIColor(rgb: 0xF5F7FA)
    var baseIconPrimaryColor: UIColor = UIColor(rgb: 0xFFFFFF)
    var baseTextPrimaryColor: UIColor = UIColor(rgb: 0xFFFFFF)
    var baseTextSecondaryColor: UIColor = UIColor(rgb: 0x8F97A3)

    var searchBackgroundColor: UIColor = UIColor(rgb: 0xFFFFFF)
    var searchPlaceholderColor: UIColor = UIColor(rgb: 0x8F97A3)

    var headerBackgroundColor: UIColor = UIColor(rgb: 0xF5F7FA)
    var headerBorderColor: UIColor  = UIColor(rgb: 0xE9EDF1)
    var headerTextPrimaryColor: UIColor = UIColor(rgb: 0x171910)
    var headerTextSecondaryColor: UIColor = UIColor(rgb: 0x8F97A3)

    var textPrimaryColor: UIColor = UIColor(rgb: 0x171910)
    var textSecondaryColor: UIColor = UIColor(rgb: 0x8F97A3)

    var tintColor: UIColor = UIColor(displayP3Red: 0.05098039216, green: 0.7450980392, blue: 0.5450980392, alpha: 1.0)
    var tintBackgroundColor: UIColor = UIColor(rgb: 0xe9fff9)
    var tabBarUnselectedItemTintColor: UIColor = UIColor(rgb: 0xC1C6CD)
    var unreadRoomIndentColor: UIColor = UIColor(rgb: 0x2E3648)
    var lineBreakColor: UIColor = UIColor(rgb: 0xDDE4EE)        
    
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
    
    var statusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }
    var scrollBarStyle: UIScrollView.IndicatorStyle = .default
    var keyboardAppearance: UIKeyboardAppearance = .light
    
    @available(iOS 12.0, *)
    var userInterfaceStyle: UIUserInterfaceStyle {
        return .light
    }

    var placeholderTextColor: UIColor = UIColor(rgb: 0x8F97A3) // Use secondary text color
    
    var selectedBackgroundColor: UIColor = UIColor(rgb: 0xF5F7FA)
    
    var callScreenButtonTintColor: UIColor = UIColor(rgb: 0xFFFFFF)
    
    var overlayBackgroundColor: UIColor = UIColor(white: 0.7, alpha: 0.5)
    var matrixSearchBackgroundImageTintColor: UIColor = UIColor(rgb: 0xE7E7E7)
    
    func applyStyle(onTabBar tabBar: UITabBar) {
        tabBar.unselectedItemTintColor = self.tabBarUnselectedItemTintColor
        tabBar.tintColor = self.tintColor
        tabBar.barTintColor = self.baseColor
        tabBar.isTranslucent = false
    }
    
    // Note: We are not using UINavigationBarAppearance on iOS 13+ atm because of UINavigationBar directly include UISearchBar on their titleView that cause crop issues with UINavigationController pop.
    func applyStyle(onNavigationBar navigationBar: UINavigationBar) {
        navigationBar.tintColor = self.tintColor
        navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: self.textPrimaryColor
        ]
        navigationBar.barTintColor = self.baseColor
        navigationBar.shadowImage = UIImage() // Remove bottom shadow

        // The navigation bar needs to be opaque so that its background color is the expected one
        navigationBar.isTranslucent = false
    }
    
    func applyStyle(onSearchBar searchBar: UISearchBar) {
        searchBar.searchBarStyle = .default
        searchBar.barTintColor = self.baseColor
        searchBar.isTranslucent = false
        searchBar.backgroundImage = UIImage() // Remove top and bottom shadow
        searchBar.tintColor = self.tintColor
        
        if #available(iOS 13.0, *) {
            searchBar.searchTextField.backgroundColor = self.searchBackgroundColor
            searchBar.searchTextField.textColor = self.searchPlaceholderColor
        } else {
            if let searchBarTextField = searchBar.vc_searchTextField {
                searchBarTextField.textColor = self.searchPlaceholderColor
            }
        }
    }
    
    func applyStyle(onTextField texField: UITextField) {
        texField.textColor = self.textPrimaryColor
        texField.tintColor = self.tintColor
    }
    
    func applyStyle(onButton button: UIButton) {
        // NOTE: Tint color does nothing by default on button type `UIButtonType.custom`
        button.tintColor = self.tintColor
        button.setTitleColor(self.tintColor, for: .normal)
    }
}
