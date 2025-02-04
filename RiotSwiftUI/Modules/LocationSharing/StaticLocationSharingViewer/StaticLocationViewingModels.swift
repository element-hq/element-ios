//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CoreLocation
import Foundation

// MARK: View model

enum StaticLocationViewingViewAction {
    case close
    case share
    case showUserLocation
}

enum StaticLocationViewingViewModelResult {
    case close
    case share(_ coordinate: CLLocationCoordinate2D)
}

// MARK: View

struct StaticLocationViewingViewState: BindableState {
    /// Map style URL
    let mapStyleURL: URL
    
    /// Current user avatarData
    let userAvatarData: AvatarInputProtocol
    
    /// Shared annotation to display existing location
    let sharedAnnotation: LocationAnnotation
    
    /// Behavior mode of the current user's location, can be hidden, only shown and shown following the user
    var showsUserLocationMode: ShowUserLocationMode = .hide
    
    var showLoadingIndicator = false
    
    var shareButtonEnabled: Bool {
        !showLoadingIndicator
    }

    let errorSubject = PassthroughSubject<LocationSharingViewError, Never>()
    
    var bindings = StaticLocationViewingViewBindings()
}

struct StaticLocationViewingViewBindings {
    var alertInfo: AlertInfo<LocationSharingAlertType>?
}
