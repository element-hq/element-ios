// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Enables to setup or update a room timeline cell view
@objc
protocol RoomCellLayoutUpdating: Themable {
    
    func updateLayoutIfNeeded(for cell: MXKRoomBubbleTableViewCell, andCellData cellData: MXKRoomBubbleCellData)
            
    func setupLayout(forIncomingTextMessageCell cell: MXKRoomBubbleTableViewCell)
    
    func setupLayout(forOutgoingTextMessageCell cell: MXKRoomBubbleTableViewCell)
    
    func setupLayout(forIncomingFileAttachmentCell cell: MXKRoomBubbleTableViewCell)
    
    func setupLayout(forOutgoingFileAttachmentCell cell: MXKRoomBubbleTableViewCell)
    
    func updateLayout(forSelectedStickerCell cell: RoomSelectedStickerBubbleCell)
    
    func maximumTextViewWidth(for cell: MXKRoomBubbleTableViewCell, cellData: MXKCellData, maximumCellWidth: CGFloat) -> CGFloat
}
