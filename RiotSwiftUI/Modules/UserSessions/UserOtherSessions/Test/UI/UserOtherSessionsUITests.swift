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

import RiotSwiftUI
import XCTest

class UserOtherSessionsUITests: MockScreenTestCase {
    func test_whenOtherSessionsWithInactiveSessionFilterPresented_correctHeaderDisplayed() {
        app.goToScreenWithIdentifier(MockUserOtherSessionsScreenState.inactiveSessions.title)

        XCTAssertTrue(app.staticTexts[VectorL10n.userOtherSessionFilterMenuInactive].exists)
        XCTAssertTrue(app.staticTexts[VectorL10n.userSessionsOverviewSecurityRecommendationsInactiveInfo].exists)
    }
    
    func test_whenOtherSessionsWithInactiveSessionFilterPresented_correctItemsDisplayed() {
        app.goToScreenWithIdentifier(MockUserOtherSessionsScreenState.inactiveSessions.title)

        XCTAssertTrue(app.buttons["iOS, Inactive for 90+ days"].exists)
    }
    
    func test_whenOtherSessionsWithUnverifiedSessionFilterPresented_correctHeaderDisplayed() {
        app.goToScreenWithIdentifier(MockUserOtherSessionsScreenState.unverifiedSessions.title)
 
        XCTAssertTrue(app.staticTexts[VectorL10n.userSessionUnverifiedShort].exists)
        XCTAssertTrue(app.staticTexts[VectorL10n.userOtherSessionUnverifiedSessionsHeaderSubtitle].exists)
    }
    
    func test_whenOtherSessionsWithUnverifiedSessionFilterPresented_correctItemsDisplayed() {
        app.goToScreenWithIdentifier(MockUserOtherSessionsScreenState.unverifiedSessions.title)
 
        XCTAssertTrue(app.buttons["iOS, Unverified · Your current session"].exists)
    }
    
    func test_whenOtherSessionsWithAllSessionFilterPresented_correctHeaderDisplayed() {
        app.goToScreenWithIdentifier(MockUserOtherSessionsScreenState.all.title)
 
        XCTAssertTrue(app.staticTexts[VectorL10n.userSessionsOverviewOtherSessionsSectionInfo].exists)
    }
    
    func test_whenOtherSessionsWithVerifiedSessionFilterPresented_correctHeaderDisplayed() {
        app.goToScreenWithIdentifier(MockUserOtherSessionsScreenState.verifiedSessions.title)
 
        XCTAssertTrue(app.staticTexts[VectorL10n.userSessionVerifiedShort].exists)
        XCTAssertTrue(app.staticTexts[VectorL10n.userOtherSessionVerifiedSessionsHeaderSubtitle].exists)
    }
}
