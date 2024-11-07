// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

class PollOutgoingWithoutSenderInfoBubbleCell: PollBaseBubbleCell, BubbleOutgoingRoomCellProtocol {
        
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.showSenderInfo = false
            
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
