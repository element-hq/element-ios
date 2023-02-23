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

/// Represents user live location
struct UserLiveLocation {
    var userId: String {
        avatarData.matrixItemId
    }
    
    var displayName: String {
        avatarData.displayName ?? userId
    }
    
    let avatarData: AvatarInputProtocol
    
    /// Location sharing start date
    let timestamp: TimeInterval
    
    /// Sharing duration from the start sharing date
    let timeout: TimeInterval

    /// Last coordinatore update date
    let lastUpdate: TimeInterval
    
    let coordinate: CLLocationCoordinate2D
}
