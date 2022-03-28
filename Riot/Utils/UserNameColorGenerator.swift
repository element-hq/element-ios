/*
 Copyright 2019 New Vector Ltd
 
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
