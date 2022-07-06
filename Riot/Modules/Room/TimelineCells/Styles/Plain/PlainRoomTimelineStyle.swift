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

class PlainRoomTimelineStyle: RoomTimelineStyle {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var theme: Theme
    
    // MARK: Public
    
    let identifier: RoomTimelineStyleIdentifier
    
    let cellLayoutUpdater: RoomCellLayoutUpdating?
    
    let cellProvider: RoomTimelineCellProvider
    
    let cellDecorator: RoomTimelineCellDecorator
     
    // MARK: - Setup
    
    init(theme: Theme) {
        self.theme = theme
        self.identifier = .plain
        self.cellLayoutUpdater = nil
        self.cellProvider = PlainRoomTimelineCellProvider()
        self.cellDecorator = PlainRoomTimelineCellDecorator()
    }
    
    // MARK: - Methods
    
    func canAddEvent(_ event: MXEvent, and roomState: MXRoomState, to cellData: MXKRoomBubbleCellData) -> Bool {
        return true
    }

    func canMerge(cellData: MXKRoomBubbleCellDataStoring, into receiverCellData: MXKRoomBubbleCellDataStoring) -> Bool {
        return true
    }
    
    func applySelectedStyleIfNeeded(toCell cell: MXKRoomBubbleTableViewCell, cellData: RoomBubbleCellData) {
        
        // Check whether the selected event belongs to this bubble
        let selectedComponentIndex = cellData.selectedComponentIndex
        if selectedComponentIndex != NSNotFound {
            
            let showTimestamp = cellData.showTimestampForSelectedComponent
            
            cell.selectComponent(UInt(selectedComponentIndex),
                                 showEditButton: false,
                                 showTimestamp: showTimestamp)
        } else {
            cell.blurred = true
        }
    }
    
    // MARK: Themable
    
    func update(theme: Theme) {
        self.theme = theme
    }
}
