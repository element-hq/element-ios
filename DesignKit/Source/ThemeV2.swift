// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

/// Theme v2. May be named again as `Theme` when the migration completed.
@objc public protocol ThemeV2 {
    
    /// Colors object
    var colors: ColorsUIKit { get }
    
    /// Fonts object
    var fonts: FontsUIKit { get }
    
    /// may contain more design components in future, like icons, audio files etc.
}

/// Theme v2 for SwiftUI.
public protocol ThemeSwiftUIType {
    
    /// Colors object
    var colors: ColorSwiftUI { get }
    
    /// Fonts object
    var fonts: FontSwiftUI { get }
    
    /// may contain more design components in future, like icons, audio files etc.
}
