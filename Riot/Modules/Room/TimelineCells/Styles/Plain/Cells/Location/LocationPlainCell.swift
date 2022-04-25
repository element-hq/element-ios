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
import MatrixSDK

class LocationPlainCell: SizableBaseRoomCell, RoomCellReactionsDisplayable, RoomCellReadMarkerDisplayable {
    
    private var locationView: RoomTimelineLocationView!
    private var event: MXEvent?
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        guard #available(iOS 14.0, *),
              let bubbleData = cellData as? RoomBubbleCellData,
              let event = bubbleData.events.last
        else {
            return
        }
        
        self.event = event
        locationView.update(theme: ThemeService.shared().theme)
        
        // Comment this line and uncomment next one to test UI of live location tile
        renderStaticLocation(event)
//        renderLiveLocation(event)
    }
    
    private func renderStaticLocation(_ event: MXEvent) {
        guard let locationContent = event.location else {
            return
        }
        
        locationView.locationDescription = locationContent.locationDescription
        
        let location = CLLocationCoordinate2D(latitude: locationContent.latitude, longitude: locationContent.longitude)
        
        let mapStyleURL = bubbleData.mxSession.vc_homeserverConfiguration().tileServer.mapStyleURL
        
        let avatarViewData: AvatarViewData?
        
        if locationContent.assetType == .user {
            avatarViewData = AvatarViewData(matrixItemId: bubbleData.senderId,
                                                displayName: bubbleData.senderDisplayName,
                                                avatarUrl: bubbleData.senderAvatarUrl,
                                                mediaManager: bubbleData.mxSession.mediaManager,
                                                fallbackImage: .matrixItem(bubbleData.senderId, bubbleData.senderDisplayName))
        } else {
            avatarViewData = nil
        }
        
        locationView.displayStaticLocation(with: RoomTimelineLocationViewData(location: location, userAvatarData: avatarViewData, mapStyleURL: mapStyleURL))
    }
    
    private func renderLiveLocation(_ event: MXEvent) {
        // TODO: - Render live location cell when live location event is handled
        
        // This code is only for testing live location cell
        // Will be completed when the live location event is handled
        
        guard let locationContent = event.location else {
            return
        }
        
        locationView.locationDescription = locationContent.locationDescription
        
        let location = CLLocationCoordinate2D(latitude: locationContent.latitude, longitude: locationContent.longitude)
        
        let mapStyleURL = bubbleData.mxSession.vc_homeserverConfiguration().tileServer.mapStyleURL
        
        let avatarViewData = AvatarViewData(matrixItemId: bubbleData.senderId,
                                            displayName: bubbleData.senderDisplayName,
                                            avatarUrl: bubbleData.senderAvatarUrl,
                                            mediaManager: bubbleData.mxSession.mediaManager,
                                            fallbackImage: .matrixItem(bubbleData.senderId, bubbleData.senderDisplayName))
        let futurDateTimeInterval = Date(timeIntervalSinceNow: 3734).timeIntervalSince1970 * 1000
        
        locationView.displayLiveLocation(with: RoomTimelineLocationViewData(location: location, userAvatarData: avatarViewData, mapStyleURL: mapStyleURL),
                                         liveLocationViewState: .outgoing(.started(futurDateTimeInterval)))
    }
    
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.backgroundColor = .clear
        roomCellContentView?.showSenderInfo = true
        roomCellContentView?.showPaginationTitle = false
        
        guard #available(iOS 14.0, *),
              let contentView = roomCellContentView?.innerContentView else {
            return
        }
        
        locationView = RoomTimelineLocationView.loadFromNib()
        
        contentView.vc_addSubViewMatchingParent(locationView)
    }
}

extension LocationPlainCell: RoomTimelineLocationViewDelegate {
    func roomTimelineLocationViewDidTapStopButton(_ roomTimelineLocationView: RoomTimelineLocationView) {
        guard let event = self.event else {
            return
        }
        
        delegate.cell(self, didRecognizeAction: kMXKRoomBubbleCellStopShareButtonPressed, userInfo: [kMXKRoomBubbleCellEventKey: event])
    }
    
    func roomTimelineLocationViewDidTapRetryButton(_ roomTimelineLocationView: RoomTimelineLocationView) {
        guard let event = self.event else {
            return
        }
        
        delegate.cell(self, didRecognizeAction: kMXKRoomBubbleCellRetryShareButtonPressed, userInfo: [kMXKRoomBubbleCellEventKey: event])
    }
}
