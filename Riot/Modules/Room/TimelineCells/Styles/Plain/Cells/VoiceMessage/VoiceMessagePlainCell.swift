// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class VoiceMessagePlainCell: SizableBaseRoomCell, RoomCellReactionsDisplayable, RoomCellReadMarkerDisplayable, RoomCellThreadSummaryDisplayable {
    
    private(set) var playbackController: VoiceMessagePlaybackController!
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        guard let data = cellData as? RoomBubbleCellData else {
            return
        }
        
        guard data.attachment.type == .voiceMessage || data.attachment.type == .audio else {
            fatalError("Invalid attachment type passed to a voice message cell.")
        }
        
        if playbackController.attachment != data.attachment {
            playbackController.attachment = data.attachment
        }
        
        self.update(theme: ThemeService.shared().theme)
    }
    
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.backgroundColor = .clear
        roomCellContentView?.showSenderInfo = true
        roomCellContentView?.showPaginationTitle = false
        
        guard let contentView = roomCellContentView?.innerContentView else {
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
    }
}
