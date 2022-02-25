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
