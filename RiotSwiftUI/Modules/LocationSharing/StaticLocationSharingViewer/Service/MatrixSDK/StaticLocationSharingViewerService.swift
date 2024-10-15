// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import CoreLocation
import Foundation

class StaticLocationSharingViewerService: StaticLocationSharingViewerServiceProtocol {
    
    // MARK: Private
    
    private let locationManager = CLLocationManager()
    
    // MARK: Public
    
    func requestAuthorizationIfNeeded() -> Bool {
        locationManager.requestAuthorizationIfNeeded()
    }
}

