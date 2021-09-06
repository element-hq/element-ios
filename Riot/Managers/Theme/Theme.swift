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
import DesignKit

/// Provide color constant values defined by the designer
/// https://app.zeplin.io/project/5c122fa790c5b4241ffa6be7/screen/5c619592daff2f1241d82e75
@objc protocol Theme: ThemeV2 {
    
    var identifier: String { get }

    var backgroundColor: UIColor { get }
    var baseColor: UIColor { get }

    var baseIconPrimaryColor: UIColor { get }
    var baseTextPrimaryColor: UIColor { get }
    var baseTextSecondaryColor: UIColor { get }

    var searchBackgroundColor: UIColor { get }
    var searchPlaceholderColor: UIColor { get }

    var headerBackgroundColor: UIColor { get }
    var headerBorderColor: UIColor { get }
    var headerTextPrimaryColor: UIColor { get }
    var headerTextSecondaryColor: UIColor { get }

    var textPrimaryColor: UIColor { get }
    var textSecondaryColor: UIColor { get }
    var textTertiaryColor: UIColor { get }

    var tintColor: UIColor { get }
    var tintBackgroundColor: UIColor { get }
    
    var tabBarUnselectedItemTintColor: UIColor { get }

    var unreadRoomIndentColor: UIColor { get }

    var lineBreakColor: UIColor { get }

    var noticeColor: UIColor { get }
    var noticeSecondaryColor: UIColor { get }

    /// Color for errors or warnings
    var warningColor: UIColor { get }

    var avatarColors: [UIColor] { get }
    
    var userNameColors: [UIColor] { get }
    
    var placeholderTextColor: UIColor { get }

    var selectedBackgroundColor: UIColor { get }
    
    // MARK: - Call Screen Specific Colors
    
    var callScreenButtonTintColor: UIColor { get }

    // MARK: - Appearance and style

    var roomInputTextBorder: UIColor { get }

    /// Status bar style to use
    var statusBarStyle: UIStatusBarStyle { get }

    var scrollBarStyle: UIScrollView.IndicatorStyle { get }

    var keyboardAppearance: UIKeyboardAppearance { get }
    
    @available(iOS 12.0, *)
    var userInterfaceStyle: UIUserInterfaceStyle { get }


    // MARK: - Colors not defined in the design palette
    
    var secondaryCircleButtonBackgroundColor: UIColor { get }

    /// fading behind dialog modals
    var overlayBackgroundColor: UIColor { get }

    /// Color to tint the search background image
    var matrixSearchBackgroundImageTintColor: UIColor { get }
    
    /// Color to use in shadows. Should be contrast to `backgroundColor`.
    var shadowColor: UIColor { get }
    
    // MARK: - Customisation methods

    
    /// Apply the theme on a button.
    ///
    /// - Parameter tabBar: The tabBar to customise.
    func applyStyle(onTabBar tabBar: UITabBar)

    /// Apply the theme on a navigation bar
    ///
    /// - Parameter navigationBar: the navigation bar to customise.
    func applyStyle(onNavigationBar navigationBar: UINavigationBar)

    ///  Apply the theme on a search bar.
    ///
    /// - Parameter searchBar: the search bar to customise.
    func applyStyle(onSearchBar searchBar: UISearchBar)
    
    ///  Apply the theme on a text field.
    ///
    /// - Parameter textField: the text field to customise.
    func applyStyle(onTextField textField: UITextField)
    
    /// Apply the theme on a button.
    ///
    /// - Parameter button: The button to customise.
    func applyStyle(onButton button: UIButton)
}
