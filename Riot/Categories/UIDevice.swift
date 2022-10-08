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
