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

class VoiceMessageIncomingBubbleCell: SizableBaseBubbleCell, BubbleCellReactionsDisplayable {
    
    private var playbackController: VoiceMessagePlaybackController!
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        guard let data = cellData as? RoomBubbleCellData else {
            return
        }
        
        guard data.attachment.type == MXKAttachmentTypeVoiceMessage || data.attachment.type == MXKAttachmentTypeAudio else {
            fatalError("Invalid attachment type passed to a voice message cell.")
        }
        
        if playbackController.attachment != data.attachment {
            playbackController.attachment = data.attachment
        }
    }
    
    override func setupViews() {
        super.setupViews()
        
        // TODO: Use constants
        let messageViewMarginRight: CGFloat = 80
        let messageLeftMargin: CGFloat = 48
        
        bubbleCellContentView?.backgroundColor = .clear
        bubbleCellContentView?.showSenderInfo = true
        bubbleCellContentView?.showPaginationTitle = false
        
        bubbleCellContentView?.innerContentViewTrailingConstraint.constant = messageViewMarginRight
        bubbleCellContentView?.innerContentViewLeadingConstraint.constant = messageLeftMargin
        
        guard let contentView = bubbleCellContentView?.innerContentView else {
            return
        }
        
        playbackController = VoiceMessagePlaybackController(mediaServiceProvider: VoiceMessageMediaServiceProvider.sharedProvider,
                                                            cacheManager: VoiceMessageAttachmentCacheManager.sharedManager)
        
        contentView.vc_addSubViewMatchingParent(playbackController.playbackView)
    }
    
    override func update(theme: Theme) {
        
        super.update(theme: theme)
        
        guard let playbackController = playbackController else {
            return
        }
        
        playbackController.playbackView.update(theme: theme)
        playbackController.playbackView.backgroundViewColor = theme.bubbleCellIncomingBackgroundColor
    }
}
