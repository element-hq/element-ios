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

import UIKit
import CoreLocation

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
    
    private override init() {
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
        return .action
    }
    
    override var activityType: UIActivity.ActivityType {
        return .shareToMapsApp
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        let url = Self.urlForMapsAppType(type, location: location)
        
        UIApplication.shared.open(url, options: [:]) { [weak self] result in
            self?.activityDidFinish(result)
        }
    }
}
