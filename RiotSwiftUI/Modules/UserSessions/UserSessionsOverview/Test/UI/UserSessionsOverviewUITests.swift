//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class UserSessionsOverviewUITests: MockScreenTestCase {
    func testCurrentSessionUnverified() {
        app.goToScreenWithIdentifier(MockUserSessionsOverviewScreenState.currentSessionUnverified.title)
        
        XCTAssertTrue(app.buttons["userSessionCardVerifyButton"].exists)
        XCTAssertTrue(app.staticTexts["userSessionCardViewDetails"].exists)
    }
    
    func testCurrentSessionVerified() {
        app.goToScreenWithIdentifier(MockUserSessionsOverviewScreenState.currentSessionVerified.title)
        XCTAssertFalse(app.buttons["userSessionCardVerifyButton"].exists)
        XCTAssertTrue(app.staticTexts["userSessionCardViewDetails"].exists)
        app.buttons["MoreOptionsMenu"].tap()
        XCTAssertTrue(app.buttons["Sign out of all other sessions"].exists)
    }
    
    func testOnlyUnverifiedSessions() {
        app.goToScreenWithIdentifier(MockUserSessionsOverviewScreenState.onlyUnverifiedSessions.title)
        
        XCTAssertTrue(app.staticTexts["userSessionsOverviewSecurityRecommendationsSection"].exists)
        XCTAssertTrue(app.staticTexts["userSessionsOverviewOtherSection"].exists)
    }
    
    func testOnlyInactiveSessions() {
        app.goToScreenWithIdentifier(MockUserSessionsOverviewScreenState.onlyInactiveSessions.title)
        
        XCTAssertTrue(app.staticTexts["userSessionsOverviewSecurityRecommendationsSection"].exists)
        XCTAssertTrue(app.staticTexts["userSessionsOverviewOtherSection"].exists)
    }
    
    func testNoOtherSessions() {
        app.goToScreenWithIdentifier(MockUserSessionsOverviewScreenState.noOtherSessions.title)
        
        XCTAssertFalse(app.staticTexts["userSessionsOverviewSecurityRecommendationsSection"].exists)
        XCTAssertFalse(app.staticTexts["userSessionsOverviewOtherSection"].exists)
        app.buttons["MoreOptionsMenu"].tap()
        XCTAssertFalse(app.buttons["Sign out of all other sessions"].exists)
    }
    
    func testWhenMoreThan5OtherSessionsThenViewAllButtonVisible() {
        app.goToScreenWithIdentifier(MockUserSessionsOverviewScreenState.currentSessionUnverified.title)
        app.swipeUp()

        XCTAssertTrue(app.buttons["ViewAllButton"].exists)
    }
    
    func testWhenLessThan5OtherSessionsThenViewAllButtonHidden() {
        app.goToScreenWithIdentifier(MockUserSessionsOverviewScreenState.onlyUnverifiedSessions.title)
        app.swipeUp()

        XCTAssertFalse(app.buttons["ViewAllButton"].exists)
    }
}
