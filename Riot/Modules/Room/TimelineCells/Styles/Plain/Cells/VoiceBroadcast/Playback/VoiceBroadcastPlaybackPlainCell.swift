// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class VoiceBroadcastPlaybackPlainCell: SizableBaseRoomCell, RoomCellReactionsDisplayable, RoomCellReadMarkerDisplayable {
    
    private var event: MXEvent?
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        guard let contentView = roomCellContentView?.innerContentView,
              let bubbleData = cellData as? RoomBubbleCellData,
              let event = bubbleData.events.last,
              let voiceBroadcastContent = VoiceBroadcastInfo(fromJSON: event.content),
              voiceBroadcastContent.state == VoiceBroadcastInfoState.started.rawValue,
              let controller = VoiceBroadcastPlaybackProvider.shared.buildVoiceBroadcastPlaybackVCForEvent(event,
                                                                                                           senderDisplayName: bubbleData.senderDisplayName,
                                                                                                           voiceBroadcastState: bubbleData.voiceBroadcastState)
        else {
            return
        }
        
        self.event = event
        self.addContentViewController(controller, on: contentView)
    }
    
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.backgroundColor = .clear
        roomCellContentView?.showSenderInfo = true
        roomCellContentView?.showPaginationTitle = false
    }
    
    // The normal flow for tapping on cell content views doesn't work for bubbles without attributed strings
    override func onContentViewTap(_ sender: UITapGestureRecognizer) {
        guard let event = self.event else {
            return
        }
        
        delegate.cell(self, didRecognizeAction: kMXKRoomBubbleCellTapOnContentView, userInfo: [kMXKRoomBubbleCellEventKey: event])
    }
    
    // The normal flow for long press on cell content views doesn't work for bubbles without attributed strings
    override func onLongPressGesture(_ longPressGestureRecognizer: UILongPressGestureRecognizer!) {
        guard let event = self.event else {
            return
        }
        delegate.cell(self, didRecognizeAction: kMXKRoomBubbleCellLongPressOnEvent, userInfo: [kMXKRoomBubbleCellEventKey: event])
    }
}

extension VoiceBroadcastPlaybackPlainCell: RoomCellThreadSummaryDisplayable {}
