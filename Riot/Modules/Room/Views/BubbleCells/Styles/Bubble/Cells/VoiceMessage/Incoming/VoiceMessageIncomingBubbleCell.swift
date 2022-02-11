// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

class VoiceMessageIncomingBubbleCell: VoiceMessageBubbleCell, BubbleIncomingRoomCellProtocol {
        
    override func setupViews() {
        super.setupViews()
        
        // TODO: Use constants
        let messageViewMarginRight: CGFloat = 80
        let messageLeftMargin: CGFloat = 48
        let playbackViewRightMargin: CGFloat = 40
        
        bubbleCellContentView?.innerContentViewTrailingConstraint.constant = messageViewMarginRight
        bubbleCellContentView?.innerContentViewLeadingConstraint.constant = messageLeftMargin
        
        playbackController.playbackView.stackViewTrailingContraint.constant = playbackViewRightMargin
        
        self.setupBubbleDecorations()
    }
    
    override func update(theme: Theme) {
                
        guard let playbackController = playbackController else {
            return
        }
        
        playbackController.playbackView.customBackgroundViewColor = theme.roomCellIncomingBubbleBackgroundColor
    }
}
