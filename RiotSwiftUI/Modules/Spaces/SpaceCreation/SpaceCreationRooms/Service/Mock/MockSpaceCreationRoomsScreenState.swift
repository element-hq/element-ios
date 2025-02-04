// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationRooms SpaceCreationRooms
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
enum MockSpaceCreationRoomsScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case defaultValues
    case valuesEntered
    
    /// The associated screen
    var screenType: Any.Type {
        SpaceCreationRooms.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockSpaceCreationRoomsScreenState] {
        [.defaultValues, .valuesEntered]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let creationParams = SpaceCreationParameters()
        switch self {
        case .defaultValues: break
        case .valuesEntered:
            for (index, room) in creationParams.newRooms.enumerated() {
                creationParams.newRooms[index] = SpaceCreationNewRoom(name: "Room \(index + 1)", defaultName: room.defaultName)
            }
        }
        let viewModel = SpaceCreationRoomsViewModel(creationParameters: creationParams)
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [viewModel],
            AnyView(SpaceCreationRooms(viewModel: viewModel.context)
                .environmentObject(AvatarViewModel.withMockedServices()))
        )
    }
}
