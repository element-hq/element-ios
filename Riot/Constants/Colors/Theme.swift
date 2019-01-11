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
@objc protocol Theme {

    var backgroundColor: UIColor { get }
    var baseColor: UIColor { get }

    var baseTextPrimaryColor: UIColor { get }
    var baseTextSecondaryColor: UIColor { get }

    var searchBackgroundColor: UIColor { get }
    var searchTextColor: UIColor { get }

    var headerBackgroundColor: UIColor { get }
    var headerBorderColor: UIColor { get }
    var headerTextPrimaryColor: UIColor { get }
    var headerTextSecondaryColor: UIColor { get }

    var textPrimaryColor: UIColor { get }
    var textSecondaryColor: UIColor { get }

    var tintColor: UIColor { get }

    var unreadRoomIndentColor: UIColor { get }

    /// Color for notifications for unread messages
    var notificationSecondaryColor: UIColor { get }
    /// Color for notifications for mention messages
    var notificationPrimaryColor: UIColor { get }

    var avatarColors: [UIColor] { get }


    // MARK: - Appearance and style


    /// Status bar style to use
    var statusBarStyle: UIStatusBarStyle { get }

    var scrollBarStyle: UIScrollViewIndicatorStyle { get }

    var keyboardAppearance : UIKeyboardAppearance { get }


    // MARK: - Colors not defined in the design palette


    /// nil is used to keep the default color
    var placeholderTextColor: UIColor? { get }

    /// nil is used to keep the default color
    var selectedBackgroundColor: UIColor? { get }

    /// fading behind dialog modals
    var overlayBackgroundColor: UIColor { get }

    /// Color to tint the search background image
    var matrixSearchBackgroundImageTintColor: UIColor { get }


    // MARK: - Customisation methods


    /// Apply the theme on a navigation bar
    ///
    /// - Parameter navigationBar: the navigation bar to customise.
    func applyStyle(onNavigationBar: UINavigationBar)

    ///  Apply the theme on a search bar.
    ///
    /// - Parameter searchBar: the search bar to customise.
    func applyStyle(onSearchBar: UISearchBar)
}
