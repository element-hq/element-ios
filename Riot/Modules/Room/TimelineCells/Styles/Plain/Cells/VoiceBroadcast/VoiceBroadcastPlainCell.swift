// 
// Copyright 2022 New Vector Ltd
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

class VoiceBroadcastPlainCell: SizableBaseRoomCell, RoomCellReactionsDisplayable, RoomCellReadMarkerDisplayable, RoomCellThreadSummaryDisplayable {
    
    private(set) var recordController: VoiceBroadcastRecordController!
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
//        guard let data = cellData as? RoomBubbleCellData else {
//            return
//        }
//
//        guard data.attachment.type == .voiceMessage || data.attachment.type == .audio else {
//            fatalError("Invalid attachment type passed to a voice message cell.")
//        }
//
//        if playbackController.attachment != data.attachment {
//            playbackController.attachment = data.attachment
//        }
        
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
        
        recordController = VoiceBroadcastRecordController()
        
        contentView.vc_addSubViewMatchingParent(recordController.recordView)
    }
    
    override func update(theme: Theme) {
        
        super.update(theme: theme)
        
        guard let recordController = recordController else {
            return
        }
        
        recordController.recordView.update(theme: theme)
    }
}
