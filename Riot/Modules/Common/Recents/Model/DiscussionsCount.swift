// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
