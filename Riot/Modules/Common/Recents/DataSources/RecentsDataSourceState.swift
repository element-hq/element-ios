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

/// The state for a room list screens.
@objcMembers
class RecentsDataSourceState: NSObject {
    
    // MARK: - Properties
    
    // MARK: Cells
    let invitesCellDataArray: [MXKRecentCellDataStoring]
    let favoriteCellDataArray: [MXKRecentCellDataStoring]
    let peopleCellDataArray: [MXKRecentCellDataStoring]
    let conversationCellDataArray: [MXKRecentCellDataStoring]
    let lowPriorityCellDataArray: [MXKRecentCellDataStoring]
    let serverNoticeCellDataArray: [MXKRecentCellDataStoring]
    
    // MARK: Notifications counts
    let favouriteMissedDiscussionsCount: MissedDiscussionsCount
    let directMissedDiscussionsCount: MissedDiscussionsCount
    let groupMissedDiscussionsCount: MissedDiscussionsCount
    
    // MARK: Unsent counts
    let unsentMessagesDirectDiscussionsCount: UInt
    let unsentMessagesGroupDiscussionsCount: UInt
    
    
    // MARK: - Setup
    init(invitesCellDataArray: [MXKRecentCellDataStoring],
         favoriteCellDataArray: [MXKRecentCellDataStoring],
         peopleCellDataArray: [MXKRecentCellDataStoring],
         conversationCellDataArray: [MXKRecentCellDataStoring],
         lowPriorityCellDataArray: [MXKRecentCellDataStoring],
         serverNoticeCellDataArray: [MXKRecentCellDataStoring],
         favouriteMissedDiscussionsCount: MissedDiscussionsCount,
         directMissedDiscussionsCount: MissedDiscussionsCount,
         groupMissedDiscussionsCount: MissedDiscussionsCount,
         unsentMessagesDirectDiscussionsCount: UInt,
         unsentMessagesGroupDiscussionsCount: UInt) {
        self.invitesCellDataArray = invitesCellDataArray
        self.favoriteCellDataArray = favoriteCellDataArray
        self.peopleCellDataArray = peopleCellDataArray
        self.conversationCellDataArray = conversationCellDataArray
        self.lowPriorityCellDataArray = lowPriorityCellDataArray
        self.serverNoticeCellDataArray = serverNoticeCellDataArray
        self.favouriteMissedDiscussionsCount = favouriteMissedDiscussionsCount
        self.directMissedDiscussionsCount = directMissedDiscussionsCount
        self.groupMissedDiscussionsCount = groupMissedDiscussionsCount
        self.unsentMessagesDirectDiscussionsCount = unsentMessagesDirectDiscussionsCount
        self.unsentMessagesGroupDiscussionsCount = unsentMessagesGroupDiscussionsCount
        super.init()
    }
}


/// Noticiations counts per section
@objcMembers
class MissedDiscussionsCount: NSObject {
    /// Regular notifications
    var count: UInt = 0
    
    /// Mentions like notications
    var highlightCount: UInt = 0
}
