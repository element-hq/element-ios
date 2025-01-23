// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
