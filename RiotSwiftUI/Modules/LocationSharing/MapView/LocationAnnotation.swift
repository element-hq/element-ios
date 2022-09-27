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
