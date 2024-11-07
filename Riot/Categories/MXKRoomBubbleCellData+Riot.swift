// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

extension MXKRoomBubbleCellData {
    
    // Indicate true if the cell data is collapsable and collapsed
    var isCollapsableAndCollapsed: Bool {
        return self.collapsable && self.collapsed
    }
    
    var cellDataTag: RoomBubbleCellDataTag {
        return RoomBubbleCellDataTag(rawValue: self.tag) ?? .message
    }
    
}
