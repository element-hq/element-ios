/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

@objc extension UIDevice {

    /// Returns 'true' if the current device has a notch
    var hasNotch: Bool {
        // Case 1: Portrait && top safe area inset >= 44
        let case1 = !UIDevice.current.orientation.isLandscape && (UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0) >= 44
        // Case 2: Lanscape && left/right safe area inset > 0
        let case2 = UIDevice.current.orientation.isLandscape && ((UIApplication.shared.keyWindow?.safeAreaInsets.left ?? 0) > 0 || (UIApplication.shared.keyWindow?.safeAreaInsets.right ?? 0) > 0)
        
        return case1 || case2
    }
    
    /// Returns if the device is a Phone
    var isPhone: Bool {
        return userInterfaceIdiom == .phone
    }
    
    var initialDisplayName: String {
        VectorL10n.userSessionsDefaultSessionDisplayName(AppInfo.current.displayName)
    }
    
}
