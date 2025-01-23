// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

class FileWithoutThumbnailIncomingBubbleCell: FileWithoutThumbnailBaseBubbleCell, BubbleIncomingRoomCellProtocol {
    
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.showSenderInfo = true
        
        roomCellContentView?.innerContentViewLeadingConstraint.constant = BubbleRoomCellLayoutConstants.incomingBubbleBackgroundMargins.left
        roomCellContentView?.innerContentViewTrailingConstraint.constant = BubbleRoomCellLayoutConstants.incomingBubbleBackgroundMargins.right
        
        self.setupBubbleDecorations()
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)
        
        self.fileAttachementView?.backgroundColor = theme.roomCellIncomingBubbleBackgroundColor
    }
}
