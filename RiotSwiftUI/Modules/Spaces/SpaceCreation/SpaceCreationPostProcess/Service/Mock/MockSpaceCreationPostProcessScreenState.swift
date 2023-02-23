// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationPostProcess SpaceCreationPostProcess
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
                .addDependency(MockAvatarService.example))
        )
    }
}
