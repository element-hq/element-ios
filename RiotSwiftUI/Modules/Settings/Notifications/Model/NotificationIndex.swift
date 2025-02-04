//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Index that determines the state of the push setting.
///
/// Silent case is un-used on iOS but keeping in for consistency of
/// definition across the platforms.
enum NotificationIndex {
    case off
    case silent
    case noisy
}

extension NotificationIndex: CaseIterable { }

extension NotificationIndex {
    /// Used to map the on/off checkmarks to an index used in the static push rule definitions.
    /// - Parameter enabled: Enabled/Disabled state.
    /// - Returns: The associated NotificationIndex
    static func index(when enabled: Bool) -> NotificationIndex {
        enabled ? .noisy : .off
    }
    
    /// Used to map from the checked state back to the index.
    var enabled: Bool {
        self != .off
    }
}
