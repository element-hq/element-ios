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
import CoreLocation

protocol LocationManagerDelegate: AnyObject {
    func locationManager(_ manager: LocationManager, didUpdateLocation location: CLLocation)
}

/// Location accuracy
enum LocationManagerAccuracy {
    case full
    case reduced
}

/// LocationManager handles device geolocalization
class LocationManager: NSObject {
    
    // MARK: - Constants
    
    private enum Constants {
        static let distanceFiler: CLLocationDistance = 200.0
        static let waitForAuthorizationStatusDelay: TimeInterval = 0.5
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let locationManager: CLLocationManager
    private var authorizationHandler: LocationAuthorizationHandler?
    
    // MARK: Public
    
    class var isLocationEnabled: Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    private(set) var accuracy: LocationManagerAccuracy
    
    var isUpdatingLocation = false
    
    var lastLocation: CLLocation?
    
    weak var delegate: LocationManagerDelegate?
    
    // MARK: - Setup
        
    init(accuracy: LocationManagerAccuracy, allowsBackgroundLocationUpdates: Bool) {

        self.accuracy = accuracy
        
        let locationManager = CLLocationManager()
        locationManager.distanceFilter = Constants.distanceFiler
        
        let desiredLocationAccuracy: CLLocationAccuracy
        
        switch accuracy {
        case .full:
            desiredLocationAccuracy = kCLLocationAccuracyNearestTenMeters
        case .reduced:
            desiredLocationAccuracy = kCLLocationAccuracyHundredMeters
        }
        
        locationManager.desiredAccuracy = desiredLocationAccuracy
        locationManager.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates
        
        // Indicate to change status bar appearance when the app uses location services in the background
        locationManager.showsBackgroundLocationIndicator = true
        
        self.locationManager = locationManager
        
        super.init()
    }
    
    // MARK: - Public
    
    /// Start monitoring user location
    func start() {
        
        self.locationManager.delegate = self
        
        switch accuracy {
        case .full:
            self.locationManager.startUpdatingLocation()
        case .reduced:
            // Only listen to significant changes
            // roughly after 500 meters moves or every 5 minutes minimum
            // as mentioned in the Apple documentation https://developer.apple.com/documentation/corelocation/cllocationmanager/1423531-startmonitoringsignificantlocati
            self.locationManager.startMonitoringSignificantLocationChanges()
        }

        self.isUpdatingLocation = true
    }
    
    /// Stop monitoring user location
    func stop() {
        
        switch accuracy {
        case .full:
            self.locationManager.stopUpdatingLocation()
        case .reduced:
            self.locationManager.stopMonitoringSignificantLocationChanges()
        }

        self.locationManager.delegate = nil
        self.isUpdatingLocation = false
    }
    
    /// Request location authorization
    func requestAuthorization(_ handler: @escaping LocationAuthorizationHandler) {
        
        let status = self.locationManager.authorizationStatus
                
        switch status {
        case .notDetermined, .authorizedWhenInUse:
            // Try to resquest always authorization
            self.tryToRequestAlwaysAuthorization(handler: handler)
        default:
            handler(self.locationAuthorizationStatus(from: status))
        }
    }
    
    // MARK: - Private
    
    // Try to request always authorization and if `locationManagerDidChangeAuthorization` is not called within `Constants.waitForAuthorizationStatusDelay` call the input handler.
    // NOTE: As pointed in the Apple doc:
    // - Core Location limits calls to requestAlwaysAuthorization(). After your app calls this method, further calls have no effect.
    // - If the user responded to requestWhenInUseAuthorization() with Allow Once, then Core Location ignores further calls to requestAlwaysAuthorization() due to the temporary authorization.
    // See https://developer.apple.com/documentation/corelocation/cllocationmanager/1620551-requestalwaysauthorization?changes=_6_6
    private func tryToRequestAlwaysAuthorization(handler: @escaping LocationAuthorizationHandler) {
        self.authorizationHandler = handler
        self.locationManager.requestAlwaysAuthorization()
        
        Timer.scheduledTimer(withTimeInterval: Constants.waitForAuthorizationStatusDelay, repeats: false) { [weak self] _ in
            guard let self = self else {
                return
            }
            
            self.authorizationRequestDidComplete(with: self.locationManager.authorizationStatus)
        }
    }
    
    private func locationAuthorizationStatus(from clLocationAuthorizationStatus: CLAuthorizationStatus) -> LocationAuthorizationStatus {
        
        let status: LocationAuthorizationStatus
        
        switch clLocationAuthorizationStatus {
        case .notDetermined:
            status = .unknown
        case .restricted, .denied:
            status = .denied
        case .authorizedAlways:
            status = .authorizedAlways
        case .authorizedWhenInUse:
            status = .authorizedInForeground
        @unknown default:
            status = .unknown
        }
        
        return status
    }
    
    private func authorizationRequestDidComplete(with status: CLAuthorizationStatus) {
        guard let authorizationHandler = self.authorizationHandler else {
            return
        }

        authorizationHandler(self.locationAuthorizationStatus(from: status))
        self.authorizationHandler = nil
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        
        let status = self.locationManager.authorizationStatus
        self.authorizationRequestDidComplete(with: status)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let lastLocation = locations.last else {
            return
        }
        
        self.lastLocation = lastLocation
        
        self.delegate?.locationManager(self, didUpdateLocation: lastLocation)
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        MXLog.debug("[LocationManager] Did resume location updates")
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        MXLog.debug("[LocationManager] Did pause location updates")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        MXLog.error("[LocationManager] Did failed", context: error)
    }
}
