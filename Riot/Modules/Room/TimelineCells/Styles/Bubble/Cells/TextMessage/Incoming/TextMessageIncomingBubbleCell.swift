// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

class TextMessageIncomingBubbleCell: TextMessageBaseBubbleCell, BubbleIncomingRoomCellProtocol {
    
    // MARK: - Overrides
    
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.showSenderInfo = true

        self.setupBubbleConstraints()
        self.setupBubbleDecorations()
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)
        
        self.textMessageContentView?.bubbleBackgroundView?.backgroundColor = theme.roomCellIncomingBubbleBackgroundColor
    }
    
    // MARK: - Private
    
    private func setupBubbleConstraints() {
        
        self.roomCellContentView?.innerContentViewLeadingConstraint.constant = BubbleRoomCellLayoutConstants.incomingBubbleBackgroundMargins.left
        
        self.roomCellContentView?.innerContentViewTrailingConstraint.constant = BubbleRoomCellLayoutConstants.incomingBubbleBackgroundMargins.right
    }
}
