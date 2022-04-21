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
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        guard #available(iOS 14.0, *),
              let bubbleData = cellData as? RoomBubbleCellData,
              let event = bubbleData.events.last
        else {
            return
        }
        
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
        
        if locationContent.assetType == .user {
            let avatarViewData = AvatarViewData(matrixItemId: bubbleData.senderId,
                                                displayName: bubbleData.senderDisplayName,
                                                avatarUrl: bubbleData.senderAvatarUrl,
                                                mediaManager: bubbleData.mxSession.mediaManager,
                                                fallbackImage: .matrixItem(bubbleData.senderId, bubbleData.senderDisplayName))
            
            locationView.displayLocation(location, userAvatarData: avatarViewData, mapStyleURL: mapStyleURL)
        } else {
            locationView.displayLocation(location, mapStyleURL: mapStyleURL)
        }
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
        let futurDateTimeInterval = Date(timeIntervalSinceNow: 3734).timeIntervalSince1970
        locationView.displayLocation(location, userAvatarData: avatarViewData, mapStyleURL: mapStyleURL, liveLocationState: .outgoingLive(generateTimerString(for: futurDateTimeInterval, isIncomingLocation: false)))
    }
    
    private func generateTimerString(for timestamp: Double,
                                     isIncomingLocation: Bool) -> String? {
        let timerString: String?
        if isIncomingLocation {
            timerString = VectorL10n.locationSharingLiveTimerIncoming(incomingTimerFormatter.string(from: Date(timeIntervalSince1970: timestamp)))
        } else if let outgoingTimer = outgoingTimerFormatter.string(from: Date(timeIntervalSince1970: timestamp).timeIntervalSinceNow) {
            timerString = VectorL10n.locationSharingLiveTimerOutgoing(outgoingTimer)
        } else {
            timerString = nil
        }
        return timerString
    }
    
    private lazy var incomingTimerFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter
    }()
    
    private lazy var outgoingTimerFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .dropAll
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .brief
        return formatter
    }()
    
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
