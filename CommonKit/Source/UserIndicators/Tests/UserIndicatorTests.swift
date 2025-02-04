// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import XCTest

class UserIndicatorTests: XCTestCase {
    var presenter: UserIndicatorPresenterSpy!
    
    override func setUp() {
        super.setUp()
        presenter = UserIndicatorPresenterSpy()
    }
    
    func makeIndicator(dismissal: UserIndicatorDismissal = .manual, callback: @escaping () -> Void = {}) -> UserIndicator {
        let request = UserIndicatorRequest(
            presenter: presenter,
            dismissal: dismissal
        )
        return UserIndicator(
            request: request,
            completion: callback
        )
    }
    
    // MARK: - State
    
    func testNewIndicatorIsPending() {
        let indicator = makeIndicator()
        XCTAssertEqual(indicator.state, .pending)
    }
    
    func testStartedIndicatorIsExecuting() {
        let indicator = makeIndicator()
        indicator.start()
        XCTAssertEqual(indicator.state, .executing)
    }
    
    func testCancelledIndicatorIsCompleted() {
        let indicator = makeIndicator()
        indicator.cancel()
        XCTAssertEqual(indicator.state, .completed)
    }
    
    // MARK: - Presenter
    
    func testStartingIndicatorPresentsUI() {
        let indicator = makeIndicator()
        indicator.start()
        XCTAssertEqual(presenter.intel, ["present()"])
    }
    
    func testAllowStartingOnlyOnce() {
        let indicator = makeIndicator()
        indicator.start()
        presenter.intel = []
        
        indicator.start()
        
        XCTAssertEqual(presenter.intel, [])
    }
    
    func testCancellingIndicatorDismissesUI() {
        let indicator = makeIndicator()
        indicator.start()
        presenter.intel = []
        
        indicator.cancel()
        
        XCTAssertEqual(presenter.intel, ["dismiss()"])
    }
    
    func testAllowCancellingOnlyOnce() {
        let indicator = makeIndicator()
        indicator.start()
        indicator.cancel()
        presenter.intel = []
        
        indicator.cancel()
        
        XCTAssertEqual(presenter.intel, [])
    }
    
    // MARK: - Dismissal
    
    func testDismissAfterTimeout() {
        let interval: TimeInterval = 0.01
        let indicator = makeIndicator(dismissal: .timeout(interval))
        
        indicator.start()
        
        let exp = expectation(description: "")
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
        
        XCTAssertEqual(indicator.state, .completed)
    }
    
    // MARK: - Completion callback
    
    func testTriggersCallbackWhenCompleted() {
        var didComplete = false
        let indicator = makeIndicator {
            didComplete = true
        }
        indicator.start()
        
        indicator.cancel()
        
        XCTAssertTrue(didComplete)
    }
}
