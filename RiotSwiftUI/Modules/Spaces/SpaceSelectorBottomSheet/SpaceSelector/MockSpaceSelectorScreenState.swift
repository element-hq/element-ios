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
enum MockSpaceSelectorScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case emptyList
    case initialList
    case selection

    /// The associated screen
    var screenType: Any.Type {
        SpaceSelector.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockSpaceSelectorScreenState] {
        [.emptyList, .initialList, .selection]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let service: MockSpaceSelectorService
        switch self {
        case .emptyList:
            service = MockSpaceSelectorService(spaceList: [])
        case .initialList:
            service = MockSpaceSelectorService()
        case .selection:
            service = MockSpaceSelectorService(selectedSpaceId: MockSpaceSelectorService.defaultSpaceList[3].id)
        }
        let viewModel = SpaceSelectorViewModel.makeViewModel(service: service, showCancel: true)
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [service, viewModel],
            AnyView(SpaceSelector(viewModel: viewModel.context))
        )
    }
}
