//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
