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

import CoreLocation
import Foundation
import SwiftUI

/// Using an enum for the screen allows you define the different state cases with
/// the relevant associated data for each case.
enum MockStaticLocationViewingScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case showUserLocation
    case showPinLocation
    
    /// The associated screen
    var screenType: Any.Type {
        StaticLocationView.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockStaticLocationViewingScreenState] {
        [.showUserLocation, .showPinLocation]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let location = CLLocationCoordinate2D(latitude: 51.4932641, longitude: -0.257096)
        let coordinateType: LocationSharingCoordinateType = self == .showUserLocation ? .user : .pin
        
        let mapStyleURL = URL(string: "https://api.maptiler.com/maps/streets/style.json?key=fU3vlMsMn4Jb6dnEIFsx")!
        let viewModel = StaticLocationViewingViewModel(mapStyleURL: mapStyleURL,
                                                       avatarData: AvatarInput(mxContentUri: "", matrixItemId: "alice:matrix.org", displayName: "Alice"),
                                                       location: location,
                                                       coordinateType: coordinateType)
        
        return ([viewModel],
                AnyView(StaticLocationView(viewModel: viewModel.context)
                    .addDependency(MockAvatarService.example)))
    }
}
