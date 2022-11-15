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
