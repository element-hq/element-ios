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
enum MockTemplateRoomListScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case noRooms
    case rooms
    
    /// The associated screen
    var screenType: Any.Type {
        TemplateRoomList.self
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let service: MockTemplateRoomListService
        switch self {
        case .noRooms:
            service = MockTemplateRoomListService(rooms: [])
        case .rooms:
            service = MockTemplateRoomListService()
        }
        let viewModel = TemplateRoomListViewModel(templateRoomListService: service)
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [service, viewModel],
            AnyView(TemplateRoomList(viewModel: viewModel.context)
                .environmentObject(AvatarViewModel.withMockedServices()))
        )
    }
}
