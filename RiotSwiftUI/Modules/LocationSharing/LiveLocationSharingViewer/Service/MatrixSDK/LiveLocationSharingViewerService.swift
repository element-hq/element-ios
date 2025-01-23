//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
import Foundation
import MatrixSDK

class LiveLocationSharingViewerService: LiveLocationSharingViewerServiceProtocol {
    
    // MARK: - Properties
    
    private(set) var usersLiveLocation: [UserLiveLocation] = []
    private let roomId: String
    private var beaconInfoSummaryListener: Any?
    private let locationManager = CLLocationManager()
    
    // MARK: Private
    
    private let session: MXSession
    
    // MARK: Public
    
    var didUpdateUsersLiveLocation: (([UserLiveLocation]) -> Void)?
    
    // MARK: - Setup
    
    init(session: MXSession, roomId: String) {
        self.session = session
        self.roomId = roomId
        
        updateUsersLiveLocation(notifyUpdate: false)
    }
    
    // MARK: - Public
    
    func isCurrentUserId(_ userId: String) -> Bool {
        session.myUserId == userId
    }
    
    func startListeningLiveLocationUpdates() {
        beaconInfoSummaryListener = session.aggregations.beaconAggregations.listenToBeaconInfoSummaryUpdateInRoom(withId: roomId) { [weak self] _ in

            self?.updateUsersLiveLocation(notifyUpdate: true)
        }
    }
    
    func stopListeningLiveLocationUpdates() {
        if let listener = beaconInfoSummaryListener {
            session.aggregations.removeListener(listener)
            beaconInfoSummaryListener = nil
        }
    }
    
    func stopUserLiveLocationSharing(completion: @escaping (Result<Void, Error>) -> Void) {
        session.locationService.stopUserLocationSharing(inRoomWithId: roomId) { response in
            
            switch response {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func requestAuthorizationIfNeeded() -> Bool {
        locationManager.requestAuthorizationIfNeeded()
    }
    
    // MARK: - Private
    
    private func updateUsersLiveLocation(notifyUpdate: Bool) {
        let beaconInfoSummaries = session.locationService.getDisplayableBeaconInfoSummaries(inRoomWithId: roomId)
        usersLiveLocation = Self.usersLiveLocation(fromBeaconInfoSummaries: beaconInfoSummaries, session: session)
        
        if notifyUpdate {
            didUpdateUsersLiveLocation?(usersLiveLocation)
        }
    }
    
    private class func usersLiveLocation(fromBeaconInfoSummaries beaconInfoSummaries: [MXBeaconInfoSummaryProtocol], session: MXSession) -> [UserLiveLocation] {
        beaconInfoSummaries.compactMap { beaconInfoSummary in
            
            let beaconInfo = beaconInfoSummary.beaconInfo
            
            guard let lastBeacon = beaconInfoSummary.lastBeacon else {
                return nil
            }
            
            let avatarData = session.avatarInput(for: beaconInfoSummary.userId)
            
            let timestamp = TimeInterval(beaconInfo.timestamp / 1000)
            let timeout = TimeInterval(beaconInfo.timeout / 1000)
            let lastUpdate = TimeInterval(lastBeacon.timestamp / 1000)
            
            let coordinate = CLLocationCoordinate2D(latitude: lastBeacon.location.latitude, longitude: lastBeacon.location.longitude)
            
            return UserLiveLocation(avatarData: avatarData,
                                    timestamp: timestamp,
                                    timeout: timeout,
                                    lastUpdate: lastUpdate,
                                    coordinate: coordinate)
        }
    }
}
