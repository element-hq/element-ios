// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixSDK

/// RoomTimelineStyle describes a room timeline style used to customize timeline appearance
@objc
protocol RoomTimelineStyle: Themable {
    
    // MARK: - Properties
    
    /// Style identifier
    var identifier: RoomTimelineStyleIdentifier { get }
    
    /// Update layout if needed for cells provided by the cell provider
    var cellLayoutUpdater: RoomCellLayoutUpdating? { get }
    
    /// Register and provide timeline cells
    var cellProvider: RoomTimelineCellProvider { get }
    
    /// Handle cell decorations (reactions, read receipts, URL preview, …)
    var cellDecorator: RoomTimelineCellDecorator { get }
    
    // MARK: - Methods
    
    /// Indicate to merge or not event in timeline
    func canAddEvent(_ event: MXEvent, and roomState: MXRoomState, to cellData: MXKRoomBubbleCellData) -> Bool

    /// Indicate to merge or not the `cellData` into `receiverCellData`
    func canMerge(cellData: MXKRoomBubbleCellDataStoring, into receiverCellData: MXKRoomBubbleCellDataStoring) -> Bool

    /// Apply selected or blurred style on cell
    func applySelectedStyleIfNeeded(toCell cell: MXKRoomBubbleTableViewCell, cellData: RoomBubbleCellData)
}
