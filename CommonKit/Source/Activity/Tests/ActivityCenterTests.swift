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

class ActivityCenterTests: XCTestCase {
    var activities: [Activity]!
    var center: ActivityCenter!
    
    override func setUp() {
        activities = []
        center = ActivityCenter()
    }
    
    func makeRequest() -> ActivityRequest {
        return ActivityRequest(
            presenter: ActivityPresenterSpy(),
            dismissal: .manual
        )
    }
    
    func testStartsActivityWhenAdded() {
        let activity = center.add(makeRequest())
        XCTAssertEqual(activity.state, .executing)
    }
    
    func testSecondActivityIsPending() {
        center.add(makeRequest()).store(in: &activities)
        let activity = center.add(makeRequest())
        XCTAssertEqual(activity.state, .pending)
    }
    
    func testSecondActivityIsExecutingWhenFirstCompleted() {
        let first = center.add(makeRequest())
        let second = center.add(makeRequest())
        
        first.cancel()
        
        XCTAssertEqual(second.state, .executing)
    }
}
