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

class VoiceMessageBubbleCell: SizableBaseBubbleCell, BubbleCellReactionsDisplayable {
    
    private var playbackView: VoiceMessagePlaybackView!
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        guard let data = cellData as? RoomBubbleCellData else {
            return
        }
        
        guard data.attachment.type == MXKAttachmentTypeVoiceMessage else {
            fatalError("Invalid attachment type passed to a voice message cell.")
        }
        
        playbackView.attachment = data.attachment
    }
    
    override func setupViews() {
        super.setupViews()
        
        bubbleCellContentView?.showSenderInfo = true
        bubbleCellContentView?.showPaginationTitle = false
        
        guard let contentView = bubbleCellContentView?.innerContentView else {
            return
        }
        
        playbackView = VoiceMessagePlaybackView.instanceFromNib()
        bubbleCellContentView?.addSubview(playbackView)
        
        contentView.vc_addSubViewMatchingParent(playbackView)
    }
}
