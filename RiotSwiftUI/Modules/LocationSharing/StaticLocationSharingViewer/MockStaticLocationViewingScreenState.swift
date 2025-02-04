//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
                                                       coordinateType: coordinateType,
                                                       service: MockStaticLocationSharingViewerService())
        
        return ([viewModel],
                AnyView(StaticLocationView(viewModel: viewModel.context)
                    .environmentObject(AvatarViewModel.withMockedServices())))
    }
}
