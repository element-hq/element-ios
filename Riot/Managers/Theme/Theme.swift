/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
    var searchResultHighlightColor: UIColor { get }

    var headerBackgroundColor: UIColor { get }
    var headerBorderColor: UIColor { get }
    var headerTextPrimaryColor: UIColor { get }
    var headerTextSecondaryColor: UIColor { get }

    var textPrimaryColor: UIColor { get }
    var textSecondaryColor: UIColor { get }
    var textTertiaryColor: UIColor { get }
    var textQuinaryColor: UIColor { get }

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
    
    var userInterfaceStyle: UIUserInterfaceStyle { get }


    // MARK: - Colors not defined in the design palette
    
    var secondaryCircleButtonBackgroundColor: UIColor { get }

    /// fading behind dialog modals
    var overlayBackgroundColor: UIColor { get }

    /// Color to tint the search background image
    var matrixSearchBackgroundImageTintColor: UIColor { get }
    
    /// Color to use in shadows. Should be contrast to `backgroundColor`.
    var shadowColor: UIColor { get }
        
    // Timeline cells

    var roomCellIncomingBubbleBackgroundColor: UIColor { get }
    
    var roomCellOutgoingBubbleBackgroundColor: UIColor { get }
    
    // Localisation Cells
    
    var roomCellLocalisationIconStartedColor: UIColor { get }
    
    var roomCellLocalisationErrorColor: UIColor { get }
    
    // MARK: - Customisation methods

    
    /// Apply the theme on a tab bar.
    ///
    /// - Parameter tabBar: The tab bar to customise.
    func applyStyle(onTabBar tabBar: UITabBar)

    /// Apply the theme on a navigation bar, without enabling the iOS 15's scroll edge appearance.
    ///
    /// - Parameter navigationBar: the navigation bar to customise.
    func applyStyle(onNavigationBar navigationBar: UINavigationBar)

    /// Apply the theme on a navigation bar.
    ///
    /// - Parameter navigationBar: the navigation bar to customise.
    /// - Parameter modernScrollEdgeAppearance: whether or not to use the iOS 15 style scroll edge appearance
    func applyStyle(onNavigationBar navigationBar: UINavigationBar,
                    withModernScrollEdgeAppearance modernScrollEdgeAppearance: Bool)
    
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
