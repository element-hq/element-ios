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

enum MockLocationSharingScreenState: MockScreenState, CaseIterable {
    case shareUserLocation
    
    var screenType: Any.Type {
        LocationSharingView.self
    }
    
    var screenView: ([Any], AnyView)  {
        
        let locationSharingService = MockLocationSharingService()
        
        let mapStyleURL = URL(string: "https://api.maptiler.com/maps/streets/style.json?key=fU3vlMsMn4Jb6dnEIFsx")!
        let viewModel = LocationSharingViewModel(mapStyleURL: mapStyleURL,
                                                 avatarData: AvatarInput(mxContentUri: "", matrixItemId: "alice:matrix.org", displayName: "Alice"),
                                                 isLiveLocationSharingEnabled: true, service: locationSharingService)
        return ([viewModel],
                AnyView(LocationSharingView(context: viewModel.context)
                            .addDependency(MockAvatarService.example)))
    }
}
