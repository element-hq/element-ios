// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class VoiceMessageOutgoingWithoutSenderInfoBubbleCell: VoiceMessagePlainCell, BubbleOutgoingRoomCellProtocol {
        
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.showSenderInfo = false

        roomCellContentView?.innerContentViewLeadingConstraint.constant = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.left
        roomCellContentView?.innerContentViewTrailingConstraint.constant = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.right
                
        playbackController.playbackView.stackViewTrailingContraint.constant = BubbleRoomCellLayoutConstants.voiceMessagePlaybackViewRightMargin
        
        self.setupBubbleDecorations()
    }
    
    override func update(theme: Theme) {
                
        guard let playbackController = playbackController else {
            return
        }
        
        playbackController.playbackView.customBackgroundViewColor = theme.roomCellOutgoingBubbleBackgroundColor
    }
}
