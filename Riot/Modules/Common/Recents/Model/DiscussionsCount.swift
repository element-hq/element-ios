// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Noticiations counts per section
@objcMembers
public class DiscussionsCount: NSObject {
    /// Number of notified rooms with regular notifications
    public let numberOfNotified: Int
    
    /// Number of highlighted rooms with mentions like notications
    public let numberOfHighlighted: Int
    
    /// Number of rooms that have unsent messages in it
    public let numberOfUnsent: Int
    
    /// Flag indicating is there any unsent
    public var hasUnsent: Bool {
        return numberOfUnsent > 0
    }
    
    /// Flag indicating is there any highlight
    public var hasHighlight: Bool {
        return numberOfHighlighted > 0
    }
    
    public static let zero: DiscussionsCount = DiscussionsCount(numberOfNotified: 0,
                                                                numberOfHighlighted: 0,
                                                                numberOfUnsent: 0)
    
    public init(numberOfNotified: Int,
                numberOfHighlighted: Int,
                numberOfUnsent: Int) {
        self.numberOfNotified = numberOfNotified
        self.numberOfHighlighted = numberOfHighlighted
        self.numberOfUnsent = numberOfUnsent
        super.init()
    }
    
    public init(withRoomListDataCounts counts: [MXRoomListDataCounts]) {
        self.numberOfNotified = counts.reduce(0, { $0 + $1.numberOfNotifiedRooms })
        self.numberOfHighlighted = counts.reduce(0, { $0 + $1.numberOfHighlightedRooms + $1.numberOfInvitedRooms })
        self.numberOfUnsent = counts.reduce(0, { $0 + $1.numberOfUnsentRooms })
        super.init()
    }
}
