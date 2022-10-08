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
