//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
import Foundation

/// Build a UIActivityViewController to share a location
class ShareLocationActivityControllerBuilder {
    func build(with location: CLLocationCoordinate2D) -> UIActivityViewController {
        UIActivityViewController(activityItems: [ShareToMapsAppActivity.urlForMapsAppType(.apple, location: location)],
                                 applicationActivities: [ShareToMapsAppActivity(type: .apple, location: location),
                                                         ShareToMapsAppActivity(type: .google, location: location),
                                                         ShareToMapsAppActivity(type: .osm, location: location)])
    }
}
