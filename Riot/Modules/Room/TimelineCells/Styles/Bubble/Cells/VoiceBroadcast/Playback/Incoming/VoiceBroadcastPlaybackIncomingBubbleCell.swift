// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class VoiceBroadcastPlaybackIncomingBubbleCell: VoiceBroadcastPlaybackBubbleCell, BubbleIncomingRoomCellProtocol {

    override func setupViews() {
        super.setupViews()
        
        // TODO: VB update margins attributes
        let leftMargin: CGFloat = BubbleRoomCellLayoutConstants.incomingBubbleBackgroundMargins.left + BubbleRoomCellLayoutConstants.pollBubbleBackgroundInsets.left
        let rightMargin: CGFloat = BubbleRoomCellLayoutConstants.incomingBubbleBackgroundMargins.right + BubbleRoomCellLayoutConstants.pollBubbleBackgroundInsets.right
        
        roomCellContentView?.innerContentViewLeadingConstraint.constant = leftMargin
        roomCellContentView?.innerContentViewTrailingConstraint.constant = rightMargin
        
        self.setupBubbleDecorations()
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)
        
        self.bubbleBackgroundColor = theme.roomCellIncomingBubbleBackgroundColor
    }
}
