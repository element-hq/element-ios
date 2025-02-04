// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
