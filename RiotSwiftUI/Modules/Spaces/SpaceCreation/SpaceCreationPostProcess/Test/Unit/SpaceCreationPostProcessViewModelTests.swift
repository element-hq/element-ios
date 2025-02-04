// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationPostProcess SpaceCreationPostProcess
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

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
