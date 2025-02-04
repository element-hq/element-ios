//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
import UIKit

extension UIActivity.ActivityType {
    static let shareToMapsApp = UIActivity.ActivityType("Element.ShareToMapsApp")
}

class ShareToMapsAppActivity: UIActivity {
    enum MapsAppType {
        case apple
        case google
        case osm
    }
    
    private let type: MapsAppType
    private let location: CLLocationCoordinate2D
    
    override private init() {
        fatalError()
    }
    
    init(type: MapsAppType, location: CLLocationCoordinate2D) {
        self.type = type
        self.location = location
    }
    
    static func urlForMapsAppType(_ type: MapsAppType, location: CLLocationCoordinate2D) -> URL {
        switch type {
        case .apple:
            return URL(string: "https://maps.apple.com?ll=\(location.latitude),\(location.longitude)&q=Pin")!
        case .google:
            return URL(string: "https://www.google.com/maps/search/?api=1&query=\(location.latitude),\(location.longitude)")!
        case .osm:
            return URL(string: "https://www.openstreetmap.org/?mlat=\(location.latitude)&mlon=\(location.longitude)")!
        }
    }
    
    override var activityTitle: String? {
        switch type {
        case .apple:
            return VectorL10n.locationSharingOpenAppleMaps
        case .google:
            return VectorL10n.locationSharingOpenGoogleMaps
        case .osm:
            return VectorL10n.locationSharingOpenOpenStreetMaps
        }
    }
    
    var activityCategory: UIActivity.Category {
        .action
    }
    
    override var activityType: UIActivity.ActivityType {
        .shareToMapsApp
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        let url = Self.urlForMapsAppType(type, location: location)
        
        UIApplication.shared.open(url, options: [:]) { [weak self] result in
            self?.activityDidFinish(result)
        }
    }
}
