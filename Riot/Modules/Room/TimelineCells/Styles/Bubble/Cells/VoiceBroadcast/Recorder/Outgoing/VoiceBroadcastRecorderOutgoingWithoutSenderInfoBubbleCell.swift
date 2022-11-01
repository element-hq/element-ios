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

class VoiceBroadcastRecorderOutgoingWithoutSenderInfoBubbleCell: VoiceBroadcastRecorderBubbleCell, BubbleOutgoingRoomCellProtocol {
        
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.showSenderInfo = false
        
        // TODO: VB update margins attributes
        let leftMargin: CGFloat = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.left + BubbleRoomCellLayoutConstants.pollBubbleBackgroundInsets.left
        let rightMargin: CGFloat = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.right + BubbleRoomCellLayoutConstants.pollBubbleBackgroundInsets.right
        
        roomCellContentView?.innerContentViewTrailingConstraint.constant = rightMargin
        roomCellContentView?.innerContentViewLeadingConstraint.constant = leftMargin
        
        self.setupBubbleDecorations()
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)
        
        self.bubbleBackgroundColor = theme.roomCellOutgoingBubbleBackgroundColor
    }
}
