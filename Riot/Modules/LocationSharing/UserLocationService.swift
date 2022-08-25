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

import CoreLocation
import Foundation
import MatrixSDK

/// UserLocationService handles live location sharing for the current user
class UserLocationService: UserLocationServiceProtocol {
    // MARK: - Constants
    
    private enum Constants {
        /// Minimum delay in milliseconds to send consecutive location for a beacon info
        static let beaconSendMinInterval: UInt64 = 5000 // 5s

        /// Delay to check for experied beacons
        static let beaconExpiredVerificationInterval: TimeInterval = 5 // 5s
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let locationManager: LocationManager
    private let session: MXSession
    
    /// All active beacon info summaries that belongs to this device
    /// Do not update location for beacon info started on another device
    private var deviceBeaconInfoSummaries: [MXBeaconInfoSummaryProtocol] = []
    
    private var beaconInfoSummaryListener: Any?
    
    private var expiredBeaconVerificationTimer: Timer?
    
    // MARK: Public
    
    // MARK: - Setup
        
    init(session: MXSession) {
        locationManager = LocationManager(accuracy: .full, allowsBackgroundLocationUpdates: BuildSettings.locationSharingEnabled)
        self.session = session
    }
    
    // MARK: - Public
        
    func requestAuthorization(_ handler: @escaping LocationAuthorizationHandler) {
        locationManager.requestAuthorization(handler)
    }
    
    func start() {
        locationManager.delegate = self
        
        // Check for existing beacon info summaries for the current device and start location tracking if needed
        setupDeviceBeaconSummaries()
        
        startListeningBeaconInfoSummaries()
        startVerifyingExpiredBeaconInfoSummaries()
    }
    
    func stop() {
        stopLocationTracking()
        stopListeningBeaconInfoSummaries()
        stopVerifyingExpiredBeaconInfoSummaries()
    }
    
    // MARK: - Private
    
    // MARK: Beacon info summary
    
    private func startVerifyingExpiredBeaconInfoSummaries() {
        let timer = Timer.scheduledTimer(withTimeInterval: Constants.beaconExpiredVerificationInterval, repeats: true) { [weak self] _ in

            self?.verifyExpiredBeaconInfoSummaries()
        }

        expiredBeaconVerificationTimer = timer
    }
    
    private func stopVerifyingExpiredBeaconInfoSummaries() {
        expiredBeaconVerificationTimer?.invalidate()
        expiredBeaconVerificationTimer = nil
    }
    
    private func verifyExpiredBeaconInfoSummaries() {
        for beaconInfoSummary in deviceBeaconInfoSummaries where beaconInfoSummary.isActive == false && beaconInfoSummary.hasStopped == false {
            // TODO: Prevent to stop several times
            // Wait for isStopping status
            self.session.locationService.stopUserLocationSharing(withBeaconInfoEventId: beaconInfoSummary.id, roomId: beaconInfoSummary.roomId) { _ in
            }
        }
        
        // Remove non active beacon info summaries
        deviceBeaconInfoSummaries = deviceBeaconInfoSummaries.filter { beaconInfoSummary in
            beaconInfoSummary.isActive
        }
    }
    
    private func getExistingDeviceBeaconSummaries() -> [MXBeaconInfoSummaryProtocol] {
        guard let userId = session.myUserId else {
            return []
        }
        
        return session.locationService.getBeaconInfoSummaries(for: userId).filter { summary in
            self.isDeviceBeaconInfoSummary(summary) && summary.isActive
        }
    }
    
    private func setupDeviceBeaconSummaries() {
        let existingDeviceBeaconInfoSummaries = getExistingDeviceBeaconSummaries()
        
        deviceBeaconInfoSummaries = existingDeviceBeaconInfoSummaries
        
        updateLocationTrackingIfNeeded()
        
        for summary in existingDeviceBeaconInfoSummaries {
            didReceiveDeviceNewBeaconInfoSummary(summary)
        }
    }
    
    private func startListeningBeaconInfoSummaries() {
        let beaconInfoSummaryListener = session.aggregations.beaconAggregations.listenToBeaconInfoSummaryUpdate { [weak self] _, beaconInfoSummary in
            
            self?.didReceiveBeaconInfoSummary(beaconInfoSummary)
        }
        
        self.beaconInfoSummaryListener = beaconInfoSummaryListener
    }
    
    private func stopListeningBeaconInfoSummaries() {
        if let listener = beaconInfoSummaryListener {
            session.aggregations.beaconAggregations.removeListener(listener)
        }
    }
    
    private func isDeviceBeaconInfoSummary(_ beaconInfoSummary: MXBeaconInfoSummaryProtocol) -> Bool {
        beaconInfoSummary.userId == session.myUserId && beaconInfoSummary.deviceId == session.myDeviceId
    }
    
    private func didReceiveBeaconInfoSummary(_ beaconInfoSummary: MXBeaconInfoSummaryProtocol) {
        guard isDeviceBeaconInfoSummary(beaconInfoSummary) else {
            return
        }
            
        let existingIndex = deviceBeaconInfoSummaries.firstIndex(where: { beaconInfoSum in
            beaconInfoSum.id == beaconInfoSummary.id
        })
        
        if beaconInfoSummary.isActive {
            if let index = existingIndex {
                deviceBeaconInfoSummaries[index] = beaconInfoSummary
            } else {
                deviceBeaconInfoSummaries.append(beaconInfoSummary)
                
                // Send location if possible to a new beacon info summary
                didReceiveDeviceNewBeaconInfoSummary(beaconInfoSummary)
            }
        } else {
            if let index = existingIndex {
                deviceBeaconInfoSummaries.remove(at: index)
            }
        }
        
        updateLocationTrackingIfNeeded()
    }

    private func didReceiveDeviceNewBeaconInfoSummary(_ beaconInfoSummary: MXBeaconInfoSummaryProtocol) {
        guard let lastLocation = locationManager.lastLocation else {
            return
        }
        
        sendLocation(lastLocation, for: beaconInfoSummary)
    }
    
    // MARK: Location sending
    
    private func sendLocation(_ location: CLLocation, for beaconInfoSummary: MXBeaconInfoSummaryProtocol) {
        guard canSendBeaconRequest(for: beaconInfoSummary) else {
            return
        }
        
        var localEcho: MXEvent?
        
        session.locationService.sendLocation(withBeaconInfoEventId: beaconInfoSummary.id,
                                             latitude: location.coordinate.latitude,
                                             longitude: location.coordinate.longitude,
                                             inRoomWithId: beaconInfoSummary.roomId,
                                             localEcho: &localEcho) { response in
            
            switch response {
            case .success:
                break
            case .failure(let error):
                MXLog.error("Fail to send location", context: error)
            }
        }
    }
    
    private func didReceiveLocation(_ location: CLLocation) {
        for deviceBaconInfoSummary in deviceBeaconInfoSummaries {
            sendLocation(location, for: deviceBaconInfoSummary)
        }
    }
    
    private func canSendBeaconRequest(for beaconInfoSummary: MXBeaconInfoSummaryProtocol) -> Bool {
        // Check if location manager is started
        guard locationManager.isUpdatingLocation else {
            return false
        }
        
        let canSendBeaconRequest: Bool
        
        if let lastBeaconTimestamp = beaconInfoSummary.lastBeacon?.timestamp {
            let currentTimestamp = Date().timeIntervalSince1970 * 1000
            
            canSendBeaconRequest = UInt64(currentTimestamp) - lastBeaconTimestamp >= Constants.beaconSendMinInterval
        } else {
            // The beacon info summary have no last beacon, we can send a request immediatly
            canSendBeaconRequest = true
        }
        
        return canSendBeaconRequest
    }
    
    // MARK: Device location
    
    private func stopLocationTracking() {
        locationManager.stop()
        locationManager.delegate = nil
    }
    
    private func updateLocationTrackingIfNeeded() {
        if deviceBeaconInfoSummaries.isEmpty {
            // Stop location tracking if there is no active beacon info summaries
            if locationManager.isUpdatingLocation {
                locationManager.stop()
            }
        } else {
            // Start location tracking if there is beacon info summaries and location tracking is stopped
            if locationManager.isUpdatingLocation == false {
                locationManager.start()
            }
        }
    }
}

// MARK: - LocationManagerDelegate

extension UserLocationService: LocationManagerDelegate {
    func locationManager(_ manager: LocationManager, didUpdateLocation location: CLLocation) {
        didReceiveLocation(location)
    }
}
