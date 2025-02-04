//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
import Foundation

extension CLLocationCoordinate2D {
    /// Compare two coordinates
    /// - parameter coordinate: another coordinate to compare
    /// - parameter precision:it represente how close you want the two coordinates
    /// - return: bool value
    func isEqual(to coordinate: CLLocationCoordinate2D, precision: Double) -> Bool {
        if fabs(latitude - coordinate.latitude) <= precision, fabs(longitude - coordinate.longitude) <= precision {
            return true
        }
        return false
    }
}
