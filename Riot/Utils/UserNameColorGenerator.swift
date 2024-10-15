/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

/// Generate a user name color from user id
@objcMembers
final class UserNameColorGenerator: NSObject {
    
    // MARK: - Properties
    
    /// User name colors.
    var userNameColors: [UIColor] = []
    
    /// Fallback color when `userNameColors` is empty.
    var defaultColor: UIColor = .black
    
    // MARK: - Public
    
    /// Generate a user name color from the user ID.
    ///
    /// - Parameter userId: The user ID of the user.
    /// - Returns: A color associated to the user ID.
    func color(from userId: String) -> UIColor {
        guard self.userNameColors.isEmpty == false else {
            return self.defaultColor
        }
        
        guard userId.isEmpty == false else {
            return self.userNameColors[0]
        }
        
        let senderNameColorIndex = Int(userId.vc_hashCode % Int32(self.userNameColors.count))
        return self.userNameColors[senderNameColorIndex]
    }
}

// MARK: - Themable
extension UserNameColorGenerator: Themable {
    
    func update(theme: Theme) {
        self.defaultColor = theme.colors.primaryContent
        self.userNameColors = theme.colors.namesAndAvatars
    }
}
