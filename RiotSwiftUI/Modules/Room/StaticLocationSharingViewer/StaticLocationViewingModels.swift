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
import Combine
import CoreLocation

// MARK: View model

enum StaticLocationViewingViewAction {
    case close
    case share
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
    
    var showLoadingIndicator: Bool = false
    
    var shareButtonEnabled: Bool {
        !showLoadingIndicator
    }

    let errorSubject = PassthroughSubject<LocationSharingViewError, Never>()
    
    var bindings = StaticLocationViewingViewBindings()
}

struct StaticLocationViewingViewBindings {
    var alertInfo: AlertInfo<LocationSharingAlertType>?
}
