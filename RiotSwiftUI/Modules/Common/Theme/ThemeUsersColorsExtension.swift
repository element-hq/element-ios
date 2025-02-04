//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

extension ThemeSwiftUI {
    /// Get the stable display user color based on userId.
    /// - Parameter userId: The user id used to hash.
    /// - Returns: The SwiftUI color for the associated userId.
    func userColor(for userId: String) -> Color {
        let senderNameColorIndex = Int(userId.vc_hashCode % Int32(colors.namesAndAvatars.count))
        return colors.namesAndAvatars[senderNameColorIndex]
    }
}
