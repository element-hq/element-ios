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

class LocationBubbleCell: SizableBaseBubbleCell, BubbleCellReactionsDisplayable {
    
    private var locationView: RoomTimelineLocationView!
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        guard #available(iOS 14.0, *),
              let bubbleData = cellData as? RoomBubbleCellData,
              let event = bubbleData.events.last,
              event.eventType == __MXEventType.roomMessage,
              event.hasLocation(),
              let content = event.content[kMXMessageContentKeyExtensibleLocation] as? [String: String],
              let geoURI = content[kMXMessageContentKeyExtensibleLocationURI]
        else {
            return
        }
        
        locationView.locationDescription = content[kMXMessageContentKeyExtensibleLocationDescription]
        
        locationView.displayGeoURI(geoURI,
                                   userIdentifier: bubbleData.senderId,
                                   userDisplayName: bubbleData.senderDisplayName,
                                   userAvatarURL: bubbleData.senderAvatarUrl,
                                   mediaManager: bubbleData.mxSession.mediaManager)
    }
    
    override func setupViews() {
        super.setupViews()
        
        bubbleCellContentView?.backgroundColor = .clear
        bubbleCellContentView?.showSenderInfo = true
        bubbleCellContentView?.showPaginationTitle = false
        
        guard let contentView = bubbleCellContentView?.innerContentView else {
            return
        }
        
        locationView = RoomTimelineLocationView.loadFromNib()
        
        contentView.vc_addSubViewMatchingParent(locationView)
    }
}
