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

import Combine
import CoreLocation
import Foundation

// MARK: - Coordinator

// MARK: View model

enum LiveLocationSharingViewerViewModelResult {
    case done
    case share(_ coordinate: CLLocationCoordinate2D)
}

// MARK: View

struct LiveLocationSharingViewerViewState: BindableState {
    /// Map style URL
    let mapStyleURL: URL
    
    /// Map annotations to display on map
    var annotations: [UserLocationAnnotation]

    /// Map annotation to focus on
    var highlightedAnnotation: LocationAnnotation?
    
    /// Live location list items
    var listItemsViewData: [LiveLocationListItemViewData]

    var showLoadingIndicator = false
    
    var shareButtonEnabled: Bool {
        !showLoadingIndicator
    }
    
    /// True to indicate that everybody stopped to share live location sharing in the room
    var isAllLocationSharingEnded: Bool {
        listItemsViewData.isEmpty
    }
    
    var isBottomSheetVisible: Bool {
        isAllLocationSharingEnded == false
    }
    
    var showMapLoadingError = false

    let errorSubject = PassthroughSubject<LocationSharingViewError, Never>()
    
    var bindings = LocationSharingViewStateBindings()
}

struct LiveLocationSharingViewerViewStateBindings {
    var alertInfo: AlertInfo<LocationSharingAlertType>?
    var showMapCreditsSheet = false
}

enum LiveLocationSharingViewerViewAction {
    case done
    case stopSharing
    case tapListItem(_ userId: String)
    case share(_ annotation: UserLocationAnnotation)
    case mapCreditsDidTap
}
