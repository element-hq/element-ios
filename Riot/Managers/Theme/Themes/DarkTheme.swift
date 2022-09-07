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
import DesignKit

/// Color constants for the dark theme
@objcMembers
class DarkTheme: NSObject, Theme {
    
    var identifier: String = ThemeIdentifier.dark.rawValue

    var backgroundColor: UIColor = UIColor(rgb: 0x15191E)

    var baseColor: UIColor {
        BuildSettings.newAppLayoutEnabled ? UIColor(rgb: 0x15191E) : UIColor(rgb: 0x21262C)
    }
    var baseIconPrimaryColor: UIColor = UIColor(rgb: 0xEDF3FF)
    var baseTextPrimaryColor: UIColor = UIColor(rgb: 0xFFFFFF)
    var baseTextSecondaryColor: UIColor = UIColor(rgb: 0xA9B2BC)

    var searchBackgroundColor: UIColor = UIColor(rgb: 0x15191E)
    var searchPlaceholderColor: UIColor = UIColor(rgb: 0xA9B2BC)
    var searchResultHighlightColor: UIColor = UIColor(rgb: 0xFCC639).withAlphaComponent(0.3)

    var headerBackgroundColor: UIColor {
        BuildSettings.newAppLayoutEnabled ? UIColor(rgb: 0x15191E) : UIColor(rgb: 0x21262C)
    }
    var headerBorderColor: UIColor  = UIColor(rgb: 0x15191E)
    var headerTextPrimaryColor: UIColor = UIColor(rgb: 0xFFFFFF)
    var headerTextSecondaryColor: UIColor = UIColor(rgb: 0xA9B2BC)

    var textPrimaryColor: UIColor = UIColor(rgb: 0xFFFFFF)
    var textSecondaryColor: UIColor = UIColor(rgb: 0xA9B2BC)
    var textTertiaryColor: UIColor = UIColor(rgb: 0x8E99A4)
    var textQuinaryColor: UIColor = UIColor(rgb: 0x394049)

    var tintColor: UIColor = UIColor(rgb: 0x0DBD8B)
    var tintBackgroundColor: UIColor = UIColor(rgb: 0x1F6954)
    var tabBarUnselectedItemTintColor: UIColor = UIColor(rgb: 0x8E99A4)
    var unreadRoomIndentColor: UIColor = UIColor(rgb: 0x2E3648)
    var lineBreakColor: UIColor = UIColor(rgb: 0x363D49)
    
    var noticeColor: UIColor = UIColor(rgb: 0xFF4B55)
    var noticeSecondaryColor: UIColor = UIColor(rgb: 0x61708B)

    var warningColor: UIColor = UIColor(rgb: 0xFF4B55)
    
    var roomInputTextBorder: UIColor = UIColor(rgb: 0x8D97A5).withAlphaComponent(0.2)

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
    
    var userInterfaceStyle: UIUserInterfaceStyle {
        return .dark
    }

    var placeholderTextColor: UIColor = UIColor(rgb: 0xA1B2D1) // Use secondary text color
    var selectedBackgroundColor: UIColor = UIColor(rgb: 0x040506)
    var callScreenButtonTintColor: UIColor = UIColor(rgb: 0xFFFFFF)
    var overlayBackgroundColor: UIColor = UIColor(white: 0.7, alpha: 0.5)
    var matrixSearchBackgroundImageTintColor: UIColor = UIColor(rgb: 0x7E7E7E)
    var secondaryCircleButtonBackgroundColor: UIColor = UIColor(rgb: 0xE3E8F0)
    
    var shadowColor: UIColor = UIColor(rgb: 0xFFFFFF)
    
    var messageTickColor: UIColor = .white
    
    var roomCellIncomingBubbleBackgroundColor: UIColor {
        return self.colors.system
    }
    
    var roomCellOutgoingBubbleBackgroundColor: UIColor = UIColor(rgb: 0x133A34)
    
    var roomCellLocalisationIconStartedColor: UIColor = UIColor(rgb: 0x5C56F5)
    
    var roomCellLocalisationErrorColor: UIColor = UIColor(rgb: 0xFF5B55)

    func applyStyle(onTabBar tabBar: UITabBar) {
        tabBar.unselectedItemTintColor = self.tabBarUnselectedItemTintColor
        tabBar.tintColor = self.tintColor
        tabBar.barTintColor = self.baseColor
        
        // Support standard scrollEdgeAppearance iOS 15 without visual issues.
        if #available(iOS 15.0, *) {
            tabBar.isTranslucent = true
        } else {
            tabBar.isTranslucent = false
        }
    }
    
    // Protocols don't support default parameter values and a protocol extension won't work for @objc
    func applyStyle(onNavigationBar navigationBar: UINavigationBar) {
        applyStyle(onNavigationBar: navigationBar, withModernScrollEdgeAppearance: false)
    }
    
    func applyStyle(onNavigationBar navigationBar: UINavigationBar,
                    withModernScrollEdgeAppearance modernScrollEdgeAppearance: Bool) {
        navigationBar.tintColor = tintColor
        
        // On iOS 15 use UINavigationBarAppearance to fix visual issues with the scrollEdgeAppearance style.
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = baseColor

            if !modernScrollEdgeAppearance {
                appearance.shadowColor = nil
            }
            appearance.titleTextAttributes = [
                .foregroundColor: textPrimaryColor
            ]
            appearance.largeTitleTextAttributes = [
                .foregroundColor: textPrimaryColor
            ]

            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = modernScrollEdgeAppearance ? nil : appearance
        } else {
            navigationBar.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: textPrimaryColor
            ]
            navigationBar.barTintColor = baseColor
            navigationBar.shadowImage = UIImage() // Remove bottom shadow
            
            // The navigation bar needs to be opaque so that its background color is the expected one
            navigationBar.isTranslucent = false
        }
    }
    
    func applyStyle(onSearchBar searchBar: UISearchBar) {
        searchBar.searchBarStyle = .default
        searchBar.barStyle = .black
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
    
    ///  MARK: - Theme v2
    var colors: ColorsUIKit = DarkColors.uiKit
    
    var fonts: FontsUIKit = FontsUIKit(values: ElementFonts())
    
}
