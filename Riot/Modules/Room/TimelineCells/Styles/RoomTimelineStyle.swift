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
