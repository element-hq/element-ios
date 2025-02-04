// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

class FileWithoutThumbnailOutoingWithoutSenderInfoBubbleCell: FileWithoutThumbnailBaseBubbleCell, BubbleOutgoingRoomCellProtocol {
    
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.showSenderInfo = false
        
        roomCellContentView?.innerContentViewLeadingConstraint.constant = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.left
        roomCellContentView?.innerContentViewTrailingConstraint.constant = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.right
        
        self.setupBubbleDecorations()
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)
        
        self.fileAttachementView?.backgroundColor = theme.roomCellOutgoingBubbleBackgroundColor
    }
}
