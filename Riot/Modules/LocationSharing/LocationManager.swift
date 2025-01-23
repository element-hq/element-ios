//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    private var authorizationReturnedSinceRequestingAlways = false
    
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
        self.authorizationReturnedSinceRequestingAlways = false
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        
        Timer.scheduledTimer(withTimeInterval: Constants.waitForAuthorizationStatusDelay, repeats: false) { [weak self] _ in
            guard let self = self, !self.authorizationReturnedSinceRequestingAlways else {
                return
            }
            
            self.authorizationAlwaysRequestDidComplete(with: self.locationManager.authorizationStatus)
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
    private func authorizationAlwaysRequestDidComplete(with status: CLAuthorizationStatus) {
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
        authorizationReturnedSinceRequestingAlways = true
        if status == .authorizedAlways {
            // LocationManager can call locationManagerDidChangeAuthorization multiple times.
            // For example it calls it at initialisation of LocationManager manager and we are also seeing it called
            // after requestAlwaysAuthorization but before the user has actually selected on option on the prompt.
            // Therefore we should only call `authorizationAlwaysRequestDidComplete` once on the success of authorizedAlways being granted.
            self.authorizationAlwaysRequestDidComplete(with: status)
        }
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

extension CLLocationManager {
    func requestAuthorizationIfNeeded() -> Bool {
        switch authorizationStatus {
        case .notDetermined:
            requestWhenInUseAuthorization()
            return false
        case .restricted, .denied:
            return false
        case .authorizedAlways, .authorizedWhenInUse, .authorized:
            return true
        @unknown default:
            return false
        }
    }
}
