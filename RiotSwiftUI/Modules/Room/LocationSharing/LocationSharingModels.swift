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
    let mapStyleURL: URL
    let avatarData: AvatarInputProtocol
    let location: CLLocationCoordinate2D?
    
    var showLoadingIndicator: Bool = false
    
    var shareButtonVisible: Bool {
        return location == nil
    }
    
    var shareButtonEnabled: Bool {
        !showLoadingIndicator
    }

    let errorSubject = PassthroughSubject<LocationSharingViewError, Never>()
    
    var bindings = LocationSharingViewStateBindings()
}

struct LocationSharingViewStateBindings {
    var alertInfo: LocationSharingErrorAlertInfo?
    var userLocation: CLLocationCoordinate2D?
}

struct LocationSharingErrorAlertInfo: Identifiable {
    enum AlertType {
        case mapLoadingError
        case userLocatingError
        case authorizationError
        case locationSharingError
    }
    
    let id: AlertType
    let title: String
    var subtitle: String? = nil
    let primaryButton: (title: String, action: (() -> Void)?)
    var secondaryButton: (title: String, action: (() -> Void)?)? = nil
}
