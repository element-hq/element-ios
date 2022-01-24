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

class PollBubbleCell: SizableBaseBubbleCell, BubbleCellReactionsDisplayable {
    
    private var pollView: UIView?
    private var event: MXEvent?
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        guard #available(iOS 14.0, *),
              let contentView = bubbleCellContentView?.innerContentView,
              let bubbleData = cellData as? RoomBubbleCellData,
              let event = bubbleData.events.last,
              event.eventType == __MXEventType.pollStart,
              let view = TimelinePollProvider.shared.buildTimelinePollViewForEvent(event) else {
            return
        }
        
        self.event = event
        
        pollView?.removeFromSuperview()
        contentView.vc_addSubViewMatchingParent(view)
        pollView = view
    }
    
    override func setupViews() {
        super.setupViews()
        
        bubbleCellContentView?.backgroundColor = .clear
        bubbleCellContentView?.showSenderInfo = true
        bubbleCellContentView?.showPaginationTitle = false
    }
    
    // The normal flow for tapping on cell content views doesn't work for bubbles without attributed strings
    func onContentViewTap(_ sender: UITapGestureRecognizer) {
        guard let event = self.event else {
            return
        }
        
        delegate.cell(self, didRecognizeAction: kMXKRoomBubbleCellTapOnContentView, userInfo: [kMXKRoomBubbleCellEventKey: event])
    }
}
