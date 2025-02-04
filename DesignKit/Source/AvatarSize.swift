// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

// Figma Avatar Sizes: https://www.figma.com/file/X4XTH9iS2KGJ2wFKDqkyed/Compound?node-id=1258%3A19678
public enum AvatarSize: Int {
    case xxSmall = 16
    case xSmall = 32
    case small = 36
    case medium = 42
    case large = 44
    case xLarge = 52
    case xxLarge = 80
}

extension AvatarSize {
    public var size: CGSize {
        return CGSize(width: self.rawValue, height: self.rawValue)
    }
}
