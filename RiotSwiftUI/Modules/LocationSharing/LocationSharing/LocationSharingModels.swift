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

// This is the equivalent of MXEventAssetType in the MatrixSDK
enum LocationSharingCoordinateType {
    case user
    case pin
}

enum LiveLocationSharingTimeout: TimeInterval {
    // Timer are in milliseconde because timestamp are in millisecond in Matrix SDK
    case short = 900000 // 15 minutes
    case medium = 3600000 // 1 hour
    case long = 28800000 // 8 hours
}

enum LocationSharingViewAction {
    case cancel
    case share
    case sharePinLocation
    case goToUserLocation
    case startLiveSharing
    case shareLiveLocation(timeout: LiveLocationSharingTimeout)
    case userDidPan
    case mapCreditsDidTap
}

enum LocationSharingViewModelResult {
    case cancel
    case share(latitude: Double, longitude: Double, coordinateType: LocationSharingCoordinateType)
    case shareLiveLocation(timeout: TimeInterval)
    case checkLiveLocationCanBeStarted(_ completion: ((Result<Void, Error>) -> Void))
}

enum LiveLocationStartError: Error {
    case powerLevelNotHighEnough
    case labFlagNotEnabled
}

enum LocationSharingViewError {
    case failedLoadingMap
    case failedLocatingUser
    case invalidLocationAuthorization
    case failedSharingLocation
}

struct LocationSharingViewState: BindableState {
    
    /// Map style URL
    let mapStyleURL: URL
    
    /// Current user avatarData
    let userAvatarData: AvatarInputProtocol
    
    /// Map annotations to display on map
    var annotations: [LocationAnnotation]

    /// Map annotation to focus on
    var highlightedAnnotation: LocationAnnotation?

    /// Indicates whether the user has moved around the map to drop a pin somewhere other than their current location
    var isPinDropSharing: Bool = false
    
    var showLoadingIndicator: Bool = false
    
    /// True to indicate to show and follow current user location
    var showsUserLocation: Bool = false
    
    /// Used to hide live location sharing features
    var isLiveLocationSharingEnabled: Bool = false
    
    var shareButtonEnabled: Bool {
        !showLoadingIndicator
    }
    
    var showMapLoadingError: Bool = false

    let errorSubject = PassthroughSubject<LocationSharingViewError, Never>()
    
    var bindings = LocationSharingViewStateBindings()
}

struct LocationSharingViewStateBindings {
    var alertInfo: AlertInfo<LocationSharingAlertType>?
    var userLocation: CLLocationCoordinate2D?
    var pinLocation: CLLocationCoordinate2D?
    var showingTimerSelector = false
    var showMapCreditsSheet = false
}

enum LocationSharingAlertType {
    case mapLoadingError
    case userLocatingError
    case authorizationError
    case locationSharingError
    case stopLocationSharingError
    case locationSharingPowerLevelError
}
