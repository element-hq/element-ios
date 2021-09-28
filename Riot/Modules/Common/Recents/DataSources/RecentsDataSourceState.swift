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
    let suggestedRoomCellDataArray: [MXKRecentCellDataStoring]
    
    // MARK: Discussion counts
    let favouriteMissedDiscussionsCount: DiscussionsCount
    let directMissedDiscussionsCount: DiscussionsCount
    let groupMissedDiscussionsCount: DiscussionsCount
    
    // MARK: - Setup
    init(invitesCellDataArray: [MXKRecentCellDataStoring],
         favoriteCellDataArray: [MXKRecentCellDataStoring],
         peopleCellDataArray: [MXKRecentCellDataStoring],
         conversationCellDataArray: [MXKRecentCellDataStoring],
         lowPriorityCellDataArray: [MXKRecentCellDataStoring],
         serverNoticeCellDataArray: [MXKRecentCellDataStoring],
         suggestedRoomCellDataArray: [MXKRecentCellDataStoring],
         favouriteMissedDiscussionsCount: DiscussionsCount,
         directMissedDiscussionsCount: DiscussionsCount,
         groupMissedDiscussionsCount: DiscussionsCount) {
        self.invitesCellDataArray = invitesCellDataArray
        self.favoriteCellDataArray = favoriteCellDataArray
        self.peopleCellDataArray = peopleCellDataArray
        self.conversationCellDataArray = conversationCellDataArray
        self.lowPriorityCellDataArray = lowPriorityCellDataArray
        self.serverNoticeCellDataArray = serverNoticeCellDataArray
        self.suggestedRoomCellDataArray = suggestedRoomCellDataArray
        self.favouriteMissedDiscussionsCount = favouriteMissedDiscussionsCount
        self.directMissedDiscussionsCount = directMissedDiscussionsCount
        self.groupMissedDiscussionsCount = groupMissedDiscussionsCount
        super.init()
    }
}
