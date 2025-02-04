// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class VoiceBroadcastRecorderOutgoingWithoutSenderInfoBubbleCell: VoiceBroadcastRecorderBubbleCell, BubbleOutgoingRoomCellProtocol {
        
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.showSenderInfo = false
        
        // TODO: VB update margins attributes
        let leftMargin: CGFloat = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.left + BubbleRoomCellLayoutConstants.pollBubbleBackgroundInsets.left
        let rightMargin: CGFloat = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.right + BubbleRoomCellLayoutConstants.pollBubbleBackgroundInsets.right
        
        roomCellContentView?.innerContentViewTrailingConstraint.constant = rightMargin
        roomCellContentView?.innerContentViewLeadingConstraint.constant = leftMargin
        
        self.setupBubbleDecorations()
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)
        
        self.bubbleBackgroundColor = theme.roomCellOutgoingBubbleBackgroundColor
    }
}
