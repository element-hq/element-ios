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

import XCTest
import Combine

@testable import RiotSwiftUI

class SpaceCreationPostProcessViewModelTests: XCTestCase {
    
    var service: MockSpaceCreationPostProcessService!
    var viewModel: SpaceCreationPostProcessViewModelProtocol!
    var context: SpaceCreationPostProcessViewModelType.Context!

    override func setUpWithError() throws {
        service = MockSpaceCreationPostProcessService(tasks: MockSpaceCreationPostProcessService.defaultTasks)
        viewModel = SpaceCreationPostProcessViewModel.makeSpaceCreationPostProcessViewModel(spaceCreationPostProcessService: service)
        context = viewModel.context
    }

    func testInitialState() {
        XCTAssertEqual(context.viewState.tasks, MockSpaceCreationPostProcessService.defaultTasks)
        XCTAssertEqual(context.viewState.errorCount, 1)
        XCTAssertEqual(context.viewState.isFinished, false)
    }
    
    func testUpateToNextTask() {
        service.simulateUpdate(tasks: MockSpaceCreationPostProcessService.nextStepTasks)
        XCTAssertEqual(context.viewState.tasks, MockSpaceCreationPostProcessService.nextStepTasks)
        XCTAssertEqual(context.viewState.errorCount, 2)
        XCTAssertEqual(context.viewState.isFinished, false)
    }

    func testLastTaskDone() {
        service.simulateUpdate(tasks: MockSpaceCreationPostProcessService.lastTaskDoneWithError)
        XCTAssertEqual(context.viewState.tasks, MockSpaceCreationPostProcessService.lastTaskDoneWithError)
        XCTAssertEqual(context.viewState.errorCount, 2)
        XCTAssertEqual(context.viewState.isFinished, true)
    }
}
