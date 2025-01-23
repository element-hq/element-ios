//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Mapbox

/// Base class to handle a map annotation
class LocationAnnotation: NSObject, MGLAnnotation {
    // MARK: - Properties
    
    // Title property is needed to enable annotation selection and callout view showing
    var title: String?
    
    let coordinate: CLLocationCoordinate2D
    
    // MARK: - Setup
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
}

/// POI map annotation
class PinLocationAnnotation: LocationAnnotation { }

/// User map annotation
class UserLocationAnnotation: LocationAnnotation {
    // MARK: - Properties
    
    var userId: String {
        avatarData.matrixItemId
    }
    
    let avatarData: AvatarInputProtocol
    
    // MARK: - Setup
    
    init(avatarData: AvatarInputProtocol,
         coordinate: CLLocationCoordinate2D) {
        self.avatarData = avatarData
                        
        super.init(coordinate: coordinate)
        super.title = self.avatarData.displayName ?? userId
    }
}

/// Invisible annotation
class InvisibleLocationAnnotation: LocationAnnotation { }
