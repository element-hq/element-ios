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
import SwiftUI
import Combine
import CoreLocation

enum LocationSharingViewAction {
    case cancel
    case share
}

enum LocationSharingViewModelResult {
    case cancel
    case share(latitude: Double, longitude: Double)
}

enum LocationSharingViewError {
    case failedLoadingMap
    case failedLocatingUser
    case invalidLocationAuthorization
    case failedSharingLocation
}

@available(iOS 14, *)
struct LocationSharingViewState: BindableState {
    
    /// Map style URL
    let mapStyleURL: URL
    
    /// Current user avatarData
    let userAvatarData: AvatarInputProtocol
    
    /// User map annotation to display existing location
    let userAnnotation: UserLocationAnnotation?
    
    /// Map annotations to display on map
    var annotations: [UserLocationAnnotation]

    /// Map annotation to focus on
    var highlightedAnnotation: UserLocationAnnotation?

    /// Indicates whether the user has moved around the map to drop a pin somewhere other than their current location
    var isPinDropSharing: Bool = false
    
    var showLoadingIndicator: Bool = false
    
    /// True to indicate to show and follow current user location
    var showsUserLocation: Bool = false
    
    /// Used to hide live location sharing features until is finished
    var isLiveLocationSharingEnabled: Bool = false
    
    var shareButtonVisible: Bool {
        return self.displayExistingLocation == false
    }
    
    var displayExistingLocation: Bool {
        return userAnnotation != nil
    }
    
    var shareButtonEnabled: Bool {
        !showLoadingIndicator
    }

    let errorSubject = PassthroughSubject<LocationSharingViewError, Never>()
    
    var bindings = LocationSharingViewStateBindings()
}

struct LocationSharingViewStateBindings {
    var alertInfo: AlertInfo<LocationSharingAlertType>?
    var userLocation: CLLocationCoordinate2D?
}

enum LocationSharingAlertType {
    case mapLoadingError
    case userLocatingError
    case authorizationError
    case locationSharingError
}
