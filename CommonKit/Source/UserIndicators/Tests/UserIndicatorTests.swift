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
