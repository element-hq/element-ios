// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Type of an event menu item. Ordering of the cases is important. See `EventMenuBuilder`.
@objc
enum EventMenuItemType: Int {
    case viewInRoom
    case copy
    case retrySending
    case cancelSending
    case cancelDownloading
    case saveMedia
    case forward
    case permalink
    case share
    case removePoll
    case endPoll
    case reactionHistory
    case viewSource
    case viewDecryptedSource
    case viewEncryption
    case report
    case remove
    case cancel
}

extension EventMenuItemType: Comparable {
    
    static func < (lhs: EventMenuItemType, rhs: EventMenuItemType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
}
