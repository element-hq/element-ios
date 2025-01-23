// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

class BubbleRoomTimelineStyle: RoomTimelineStyle {
    
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
        self.identifier = .bubble
        self.cellLayoutUpdater = BubbleRoomCellLayoutUpdater(theme: theme)
        self.cellProvider = BubbleRoomTimelineCellProvider()
        self.cellDecorator = BubbleRoomTimelineCellDecorator()
    }
    
    // MARK: - Public
    
    func canAddEvent(_ event: MXEvent, and roomState: MXRoomState, to cellData: MXKRoomBubbleCellData) -> Bool {
        return false
    }

    func canMerge(cellData: MXKRoomBubbleCellDataStoring, into receiverCellData: MXKRoomBubbleCellDataStoring) -> Bool {
        return false
    }
    
    func applySelectedStyleIfNeeded(toCell cell: MXKRoomBubbleTableViewCell, cellData: RoomBubbleCellData) {
        
        // Check whether the selected event belongs to this bubble
        let selectedComponentIndex = cellData.selectedComponentIndex
        if selectedComponentIndex != NSNotFound {
            
            cell.selectComponent(UInt(selectedComponentIndex),
                                 showEditButton: false,
                                 showTimestamp: false)
            
            self.cellDecorator.addTimestampLabel(toCell: cell, cellData: cellData)
        } else {
            cell.blurred = true
        }
    }
    
    // MARK: Themable
    
    func update(theme: Theme) {
        self.theme = theme        
        self.cellLayoutUpdater?.update(theme: theme)
    }
    
}
