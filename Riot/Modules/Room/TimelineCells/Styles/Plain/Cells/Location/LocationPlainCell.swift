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
        
        guard let bubbleData = cellData as? RoomBubbleCellData,
              let event = bubbleData.events.last
        else {
            return
        }
        
        locationView.update(theme: ThemeService.shared().theme)
        locationView.delegate = self
        self.event = event
        
        if bubbleData.cellDataTag == .location {
            renderStaticLocation(event)
        } else if bubbleData.cellDataTag == .liveLocation,
                  let beaconInfoSummary = bubbleData.beaconInfoSummary {
            renderLiveLocation(beaconInfoSummary)
        }
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
    
    private func renderLiveLocation(_ beaconInfoSummary: MXBeaconInfoSummaryProtocol) {
        let liveLocationState: TimelineLiveLocationViewState = locationSharingViewState(from: beaconInfoSummary)
        let avatarViewData = AvatarViewData(matrixItemId: bubbleData.senderId,
                                            displayName: bubbleData.senderDisplayName,
                                            avatarUrl: bubbleData.senderAvatarUrl,
                                            mediaManager: bubbleData.mxSession.mediaManager,
                                            fallbackImage: .matrixItem(bubbleData.senderId, bubbleData.senderDisplayName))
        let mapStyleURL = bubbleData.mxSession.vc_homeserverConfiguration().tileServer.mapStyleURL
        
        locationView.displayLiveLocation(with: RoomTimelineLocationViewData(location: nil, userAvatarData: avatarViewData, mapStyleURL: mapStyleURL),
                                         liveLocationViewState: liveLocationState)
    }
    
    private func locationSharingViewState(from beaconInfoSummary: MXBeaconInfoSummaryProtocol) -> TimelineLiveLocationViewState {
        
        let viewState: TimelineLiveLocationViewState
        
        let liveLocationStatus: LiveLocationSharingStatus
        
        if beaconInfoSummary.hasStopped || beaconInfoSummary.hasExpired {
            liveLocationStatus = .stopped
        } else if let lastBeacon = beaconInfoSummary.lastBeacon {
            
            let expiryTimeinterval = TimeInterval(beaconInfoSummary.expiryTimestamp/1000) // Timestamp is in millisecond in the SDK
            
            let coordinate = CLLocationCoordinate2D(latitude: lastBeacon.location.latitude, longitude: lastBeacon.location.longitude)
            
            liveLocationStatus = .started(coordinate, expiryTimeinterval)
        } else {
            liveLocationStatus = .starting
        }
        
        if beaconInfoSummary.userId == bubbleData.mxSession.myUserId {
            viewState = .outgoing(liveLocationStatus)
        } else {
            viewState = .incoming(liveLocationStatus)
        }
        
        return viewState
    }
    
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.backgroundColor = .clear
        roomCellContentView?.showSenderInfo = true
        roomCellContentView?.showPaginationTitle = false
        
        guard let contentView = roomCellContentView?.innerContentView else {
                  return
              }
        
        locationView = RoomTimelineLocationView.loadFromNib()
        
        contentView.vc_addSubViewMatchingParent(locationView)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.event = nil
    }
    
    override func onLongPressGesture(_ longPressGestureRecognizer: UILongPressGestureRecognizer!) {
        
        var userInfo: [String: Any]?
        
        if let event = self.event {
            userInfo = [kMXKRoomBubbleCellEventKey: event]
        }
        
        delegate.cell(self, didRecognizeAction: kMXKRoomBubbleCellLongPressOnEvent, userInfo: userInfo)
    }
}

extension LocationPlainCell: RoomTimelineLocationViewDelegate {
    func roomTimelineLocationViewDidTapStopButton(_ roomTimelineLocationView: RoomTimelineLocationView) {
        delegate.cell(self, didRecognizeAction: kMXKRoomBubbleCellStopShareButtonPressed, userInfo: nil)
    }
    
    func roomTimelineLocationViewDidTapRetryButton(_ roomTimelineLocationView: RoomTimelineLocationView) {
        delegate.cell(self, didRecognizeAction: kMXKRoomBubbleCellRetryShareButtonPressed, userInfo: nil)
    }
}
