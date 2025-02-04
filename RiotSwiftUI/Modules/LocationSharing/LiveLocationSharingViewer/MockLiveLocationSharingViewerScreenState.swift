//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

/// Using an enum for the screen allows you define the different state cases with
/// the relevant associated data for each case.
enum MockLiveLocationSharingViewerScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case currentUser
    case multipleUsers
    
    /// The associated screen
    var screenType: Any.Type {
        LiveLocationSharingViewer.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockLiveLocationSharingViewerScreenState] {
        [.currentUser, .multipleUsers]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let service: LiveLocationSharingViewerServiceProtocol
        
        switch self {
        case .currentUser:
            service = MockLiveLocationSharingViewerService()
        case .multipleUsers:
            service = MockLiveLocationSharingViewerService(generateRandomUsers: true)
        }
                
        let mapStyleURL = URL(string: "https://api.maptiler.com/maps/streets/style.json?key=fU3vlMsMn4Jb6dnEIFsx")!
        
        let viewModel = LiveLocationSharingViewerViewModel(mapStyleURL: mapStyleURL, service: service)
        
        // can simulate service and viewModel actions here if needs be.

        return (
            [service, viewModel],
            AnyView(LiveLocationSharingViewer(viewModel: viewModel.context))
        )
    }
}
