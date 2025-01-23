// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationPostProcess SpaceCreationPostProcess
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
enum MockSpaceCreationPostProcessScreenState: MockScreenState {
    static var screenStates: [MockScreenState] = [MockSpaceCreationPostProcessScreenState.running, MockSpaceCreationPostProcessScreenState.done, MockSpaceCreationPostProcessScreenState.doneWithError]
    
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case running
    case done
    case doneWithError

    /// The associated screen
    var screenType: Any.Type {
        SpaceCreationPostProcess.self
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let service: MockSpaceCreationPostProcessService
        switch self {
        case .running:
            service = MockSpaceCreationPostProcessService()
        case .done:
            service = MockSpaceCreationPostProcessService(tasks: MockSpaceCreationPostProcessService.lastTaskDoneSuccesfully)
        case .doneWithError:
            service = MockSpaceCreationPostProcessService(tasks: MockSpaceCreationPostProcessService.lastTaskDoneWithError)
        }
        let viewModel = SpaceCreationPostProcessViewModel.makeSpaceCreationPostProcessViewModel(spaceCreationPostProcessService: service)
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [service, viewModel],
            AnyView(SpaceCreationPostProcess(viewModel: viewModel.context)
                .environmentObject(AvatarViewModel.withMockedServices()))
        )
    }
}
