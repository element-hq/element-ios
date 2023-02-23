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

/// Using an enum for the screen allows you define the different state cases with
/// the relevant associated data for each case.
enum MockRoomUpgradeScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case initial

    /// The associated screen
    var screenType: Any.Type {
        RoomUpgrade.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockRoomUpgradeScreenState] {
        [.initial]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let service: MockRoomUpgradeService
        switch self {
        case .initial:
            service = MockRoomUpgradeService()
        }
        let viewModel = RoomUpgradeViewModel.makeRoomUpgradeViewModel(roomUpgradeService: service)
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [service, viewModel],
            AnyView(RoomUpgrade(viewModel: viewModel.context)
                .addDependency(MockAvatarService.example))
        )
    }
}
