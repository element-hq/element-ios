//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest
@testable import RiotSwiftUI

class UserSessionNameViewModelTests: XCTestCase {
    var viewModel: UserSessionNameViewModelProtocol!
    var context: UserSessionNameViewModelType.Context!
    
    override func setUpWithError() throws {
        viewModel = UserSessionNameViewModel(sessionInfo: .mockPhone())
        context = viewModel.context
    }

    func testClearingName() {
        // Given an unedited name.
        XCTAssertFalse(context.viewState.canUpdateName, "The done button should be disabled when the name hasn't changed.")
        
        // When clearing the name.
        context.sessionName = ""
        
        // Then the done button should remain be disabled.
        XCTAssertFalse(context.viewState.canUpdateName, "The done button should be disabled when the name is empty.")
    }
    
    func testChangingName() {
        // Given an unedited name.
        XCTAssertFalse(context.viewState.canUpdateName, "The done button should be disabled when the name hasn't changed.")
        
        // When changing the name.
        context.sessionName = "Alice's iPhone"
        
        // Then the done button should be enabled.
        XCTAssertTrue(context.viewState.canUpdateName, "The done button should be enabled when the name has been changed.")
    }
    
    func testCancelIsCalled() {
        viewModel.completion = { result in
            guard case .cancel = result else {
                XCTFail()
                return
            }
        }
        
        viewModel.context.send(viewAction: .cancel)
    }
    
    func testLearnMoreIsCalled() {
        viewModel.completion = { result in
            guard case .learnMore = result else {
                XCTFail()
                return
            }
        }
        
        viewModel.context.send(viewAction: .learnMore)
    }
    
    func testUpdateNameIsCalled() {
        viewModel.completion = { result in
            guard case let .updateName(name) = result else {
                XCTFail()
                return
            }
            XCTAssertEqual(name, "Element Mobile: iOS")
        }
        
        viewModel.context.send(viewAction: .done)
    }
}
