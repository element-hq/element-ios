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
import CoreLocation

@available(iOS 14.0, *)
enum MockLocationSharingScreenState: MockScreenState, CaseIterable {
    case shareUserLocation
    case displayExistingLocation
    
    var screenType: Any.Type {
        LocationSharingView.self
    }
    
    var screenView: ([Any], AnyView)  {
        
        var location: CLLocationCoordinate2D?
        if self == .displayExistingLocation {
            location = CLLocationCoordinate2D(latitude: 51.4932641, longitude: -0.257096)
        }
        
        let mapStyleURL = URL(string: "https://api.maptiler.com/maps/streets/style.json?key=fU3vlMsMn4Jb6dnEIFsx")!
        let viewModel = LocationSharingViewModel(mapStyleURL: mapStyleURL,
                                                 avatarData: AvatarInput(mxContentUri: "", matrixItemId: "", displayName: "Alice"),
                                                 location: location)
        return ([viewModel],
                AnyView(LocationSharingView(context: viewModel.context)
                            .addDependency(MockAvatarService.example)))
    }
}
