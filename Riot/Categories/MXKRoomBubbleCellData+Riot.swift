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

extension MXKRoomBubbleCellData {
    
    // Indicate true if the cell data is collapsable and collapsed
    var isCollapsableAndCollapsed: Bool {
        return self.collapsable && self.collapsed
    }
    
    var cellDataTag: RoomBubbleCellDataTag {
        return RoomBubbleCellDataTag(rawValue: self.tag) ?? .message
    }
    
}
