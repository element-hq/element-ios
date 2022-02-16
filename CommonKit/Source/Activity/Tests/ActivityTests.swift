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

class ActivityTests: XCTestCase {
    var presenter: ActivityPresenterSpy!
    
    override func setUp() {
        super.setUp()
        presenter = ActivityPresenterSpy()
    }
    
    func makeActivity(dismissal: ActivityDismissal = .manual, callback: @escaping () -> Void = {}) -> Activity {
        let request = ActivityRequest(
            presenter: presenter,
            dismissal: dismissal
        )
        return Activity(
            request: request,
            completion: callback
        )
    }
    
    // MARK: - State
    
    func testNewActivityIsPending() {
        let activity = makeActivity()
        XCTAssertEqual(activity.state, .pending)
    }
    
    func testStartedActivityIsExecuting() {
        let activity = makeActivity()
        activity.start()
        XCTAssertEqual(activity.state, .executing)
    }
    
    func testCancelledActivityIsCompleted() {
        let activity = makeActivity()
        activity.cancel()
        XCTAssertEqual(activity.state, .completed)
    }
    
    // MARK: - Presenter
    
    func testStartingActivityPresentsUI() {
        let activity = makeActivity()
        activity.start()
        XCTAssertEqual(presenter.intel, ["present()"])
    }
    
    func testAllowStartingOnlyOnce() {
        let activity = makeActivity()
        activity.start()
        presenter.intel = []
        
        activity.start()
        
        XCTAssertEqual(presenter.intel, [])
    }
    
    func testCancellingActivityDismissesUI() {
        let activity = makeActivity()
        activity.start()
        presenter.intel = []
        
        activity.cancel()
        
        XCTAssertEqual(presenter.intel, ["dismiss()"])
    }
    
    func testAllowCancellingOnlyOnce() {
        let activity = makeActivity()
        activity.start()
        activity.cancel()
        presenter.intel = []
        
        activity.cancel()
        
        XCTAssertEqual(presenter.intel, [])
    }
    
    // MARK: - Dismissal
    
    func testDismissAfterTimeout() {
        let interval: TimeInterval = 0.01
        let activity = makeActivity(dismissal: .timeout(interval))
        
        activity.start()
        
        let exp = expectation(description: "")
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
        
        XCTAssertEqual(activity.state, .completed)
    }
    
    // MARK: - Completion callback
    
    func testTriggersCallbackWhenCompleted() {
        var didComplete = false
        let activity = makeActivity {
            didComplete = true
        }
        activity.start()
        
        activity.cancel()
        
        XCTAssertTrue(didComplete)
    }
}
