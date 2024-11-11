// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import UIKit

@objcMembers
class RoomMatrixRTCCallCell: RoomCallBaseCell {
    private static var className: String { String(describing: self) }
    
    //  MARK: - MXKCellRendering
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        guard let bubbleCellData = cellData as? RoomBubbleCellData else { return }
        let roomID = bubbleCellData.roomId
        guard let room = bubbleCellData.mxSession.room(withRoomId: roomID) else { return }
        
        room.summary.setRoomAvatarImageIn(innerContentView.avatarImageView)
        innerContentView.avatarImageView.defaultBackgroundColor = .clear
        innerContentView.callerNameLabel.text = room.summary.displayName
        statusText = VectorL10n.callUnsupportedMatrixRtcCall
        bottomContentView = nil // Expands the size of the status stack.
    }
}
