// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class VoiceBroadcastRecorderPlainBubbleCell: VoiceBroadcastRecorderBubbleCell {
    
    override func setupViews() {
        super.setupViews()
        
        // TODO: VB update margins attributes
        let leftMargin: CGFloat = BubbleRoomCellLayoutConstants.incomingBubbleBackgroundMargins.left + BubbleRoomCellLayoutConstants.pollBubbleBackgroundInsets.left
        let rightMargin: CGFloat = 15 + BubbleRoomCellLayoutConstants.pollBubbleBackgroundInsets.right
        
        roomCellContentView?.innerContentViewLeadingConstraint.constant = leftMargin
        roomCellContentView?.innerContentViewTrailingConstraint.constant = rightMargin
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)
        
        self.bubbleBackgroundColor = theme.roomCellIncomingBubbleBackgroundColor
    }
}
