// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import XCTest

class UserIndicatorQueueTests: XCTestCase {
    var indicators: [UserIndicator]!
    var queue: UserIndicatorQueue!
    
    override func setUp() {
        indicators = []
        queue = UserIndicatorQueue()
    }
    
    func makeRequest() -> UserIndicatorRequest {
        return UserIndicatorRequest(
            presenter: UserIndicatorPresenterSpy(),
            dismissal: .manual
        )
    }
    
    func testStartsIndicatorWhenAdded() {
        let indicator = queue.add(makeRequest())
        XCTAssertEqual(indicator.state, .executing)
    }
    
    func testSecondIndicatorIsPending() {
        queue.add(makeRequest()).store(in: &indicators)
        let indicator = queue.add(makeRequest())
        XCTAssertEqual(indicator.state, .pending)
    }
    
    func testSecondIndicatorIsExecutingWhenFirstCompleted() {
        let first = queue.add(makeRequest())
        let second = queue.add(makeRequest())
        
        first.cancel()
        
        XCTAssertEqual(second.state, .executing)
    }
}
