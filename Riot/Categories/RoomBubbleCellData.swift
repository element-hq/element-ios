// 
// Copyright 2020 New Vector Ltd
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

@objc extension RoomBubbleCellData {
    
    /// Gathers all collapsable events in both directions (previous and next)
    /// - Returns: Array of events containing collapsable events in both sides.
    func allLinkedEvents() -> [MXEvent] {
        var result: [MXEvent] = []
        
        //  add prev linked events
        var prevBubbleData = prevCollapsableCellData
        while prevBubbleData != nil {
            // swiftlint:disable force_unwrapping
            result.append(contentsOf: prevBubbleData!.events)
            // swiftlint:enable force_unwrapping
            prevBubbleData = prevBubbleData?.prevCollapsableCellData
        }
        
        //  add self events
        result.append(contentsOf: events)
        
        //  add next linked events
        var nextBubbleData = nextCollapsableCellData
        while nextBubbleData != nil {
            // swiftlint:disable force_unwrapping
            result.append(contentsOf: nextBubbleData!.events)
            // swiftlint:enable force_unwrapping
            nextBubbleData = nextBubbleData?.nextCollapsableCellData
        }
        
        return result
    }
    
}
