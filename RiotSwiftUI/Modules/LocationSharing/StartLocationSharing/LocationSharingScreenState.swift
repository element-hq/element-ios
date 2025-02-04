//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
import Foundation
import SwiftUI

enum MockLocationSharingScreenState: MockScreenState, CaseIterable {
    case shareUserLocation
    
    var screenType: Any.Type {
        LocationSharingView.self
    }
    
    var screenView: ([Any], AnyView) {
        let locationSharingService = MockLocationSharingService()
        
        let mapStyleURL = URL(string: "https://api.maptiler.com/maps/streets/style.json?key=fU3vlMsMn4Jb6dnEIFsx")!
        let viewModel = LocationSharingViewModel(mapStyleURL: mapStyleURL,
                                                 avatarData: AvatarInput(mxContentUri: "", matrixItemId: "alice:matrix.org", displayName: "Alice"),
                                                 isLiveLocationSharingEnabled: true, service: locationSharingService)
        return ([viewModel],
                AnyView(LocationSharingView(context: viewModel.context)
                    .environmentObject(AvatarViewModel.withMockedServices())))
    }
}
