// 
// Copyright 2022 New Vector Ltd
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

@testable import Element

final class ReviewSessionAlertSnoozeControllerTests: XCTestCase {

    private let snoozeDateKey = "ReviewSessionAlertSnoozeController_snoozeDateKey"
    private var userDefaults = UserDefaults(suiteName: "testSuit")!
    private var sut: ReviewSessionAlertSnoozeController!
    
    override func setUpWithError() throws {
        userDefaults.removePersistentDomain(forName: "testSuit")
        sut = ReviewSessionAlertSnoozeController(userDefaults: userDefaults)
    }

    func test_whenAlertNotSnoozedBefore_isSnoozedFalse() {
        XCTAssertFalse(sut.isSnoozed())
    }
    
    func test_whenAlertSnoozedYesterday_isSnoozedTrue() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        userDefaults.set(yesterday, forKey: snoozeDateKey)
        XCTAssertTrue(sut.isSnoozed())
    }
    
    func test_whenAlertSnoozed8DaysAgo_isSnoozedFalse() {
        let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: Date())
        userDefaults.set(eightDaysAgo, forKey: snoozeDateKey)
        XCTAssertFalse(sut.isSnoozed())
    }
    
    func test_whenAlertSnoozed7DaysAgo_isSnoozedTrue() {
        let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        userDefaults.set(eightDaysAgo, forKey: snoozeDateKey)
        XCTAssertTrue(sut.isSnoozed())
    }
    
    func test_whenAlertSnoozed_isSnoozedTrue() {
        XCTAssertFalse(sut.isSnoozed())
        sut.snooze()
        XCTAssertTrue(sut.isSnoozed())
    }
    
    func test_whenClearSnooze_isSnoozedFalse() {
        sut.snooze()
        XCTAssertTrue(sut.isSnoozed())
        sut.clearSnooze()
        XCTAssertFalse(sut.isSnoozed())
    }
}
