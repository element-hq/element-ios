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
        let buttonLearnMore = app.buttons["\(VectorL10n.userSessionsOverviewSecurityRecommendationsInactiveInfo) \(VectorL10n.userSessionLearnMore)"]
        XCTAssertTrue(buttonLearnMore.exists)
        buttonLearnMore.tap()
        XCTAssertTrue(app.staticTexts[VectorL10n.userSessionInactiveSessionTitle].exists)
    }
    
    func test_whenOtherSessionsWithInactiveSessionFilterPresented_correctItemsDisplayed() {
        app.goToScreenWithIdentifier(MockUserOtherSessionsScreenState.inactiveSessions.title)

        XCTAssertTrue(app.buttons["iOS, Inactive for 90+ days"].exists)
    }
    
    func test_whenOtherSessionsWithUnverifiedSessionFilterPresented_correctHeaderDisplayed() {
        app.goToScreenWithIdentifier(MockUserOtherSessionsScreenState.unverifiedSessions.title)
        XCTAssertTrue(app.staticTexts[VectorL10n.userSessionUnverifiedShort].exists)
        XCTAssertTrue(app.staticTexts[VectorL10n.userOtherSessionFilterMenuUnverified].exists)
        let buttonLearnMore = app.buttons["\(VectorL10n.userOtherSessionUnverifiedSessionsHeaderSubtitle) \(VectorL10n.userSessionLearnMore)"]
        XCTAssertTrue(buttonLearnMore.exists)
        buttonLearnMore.tap()
        XCTAssertTrue(app.staticTexts[VectorL10n.userSessionUnverifiedSessionTitle].exists)
    }
    
    func test_whenOtherSessionsWithUnverifiedSessionFilterPresented_correctItemsDisplayed() {
        app.goToScreenWithIdentifier(MockUserOtherSessionsScreenState.unverifiedSessions.title)
 
        XCTAssertTrue(app.buttons["iOS, Unverified · Your current session"].exists)
    }
    
    func test_whenOtherSessionsWithAllSessionFilterPresented_correctHeaderDisplayed() {
        app.goToScreenWithIdentifier(MockUserOtherSessionsScreenState.all.title)
 
        XCTAssertTrue(app.buttons[VectorL10n.userSessionsOverviewOtherSessionsSectionInfo].exists)
    }
    
    func test_whenOtherSessionsWithVerifiedSessionFilterPresented_correctHeaderDisplayed() {
        app.goToScreenWithIdentifier(MockUserOtherSessionsScreenState.verifiedSessions.title)
        XCTAssertTrue(app.staticTexts[VectorL10n.userSessionVerifiedShort].exists)
        XCTAssertTrue(app.staticTexts[VectorL10n.userOtherSessionFilterMenuVerified].exists)
        let buttonLearnMore = app.buttons["\(VectorL10n.userOtherSessionVerifiedSessionsHeaderSubtitle) \(VectorL10n.userSessionLearnMore)"]
        XCTAssertTrue(buttonLearnMore.exists)
        buttonLearnMore.tap()
        XCTAssertTrue(app.staticTexts[VectorL10n.userSessionVerifiedSessionTitle].exists)
    }
    
    func test_whenOtherSessionsMoreMenuButtonSelected_selectSessionsButtonExists() {
        app.goToScreenWithIdentifier(MockUserOtherSessionsScreenState.all.title)
        
        app.buttons["More"].tap()
        XCTAssertTrue(app.buttons["Select sessions"].exists)
    }
    
    func test_whenOtherSessionsSelectSessionsSelected_navBarContainsCorrectButtons() {
        app.goToScreenWithIdentifier(MockUserOtherSessionsScreenState.all.title)
        
        app.buttons["More"].tap()
        app.buttons["Select sessions"].tap()
        XCTAssertTrue(app.buttons["Select All"].exists)
        XCTAssertTrue(app.buttons["Cancel"].exists)
    }
    
    func test_whenOtherSessionsSelectAllSelected_navBarContainsCorrectButtons() {
        app.goToScreenWithIdentifier(MockUserOtherSessionsScreenState.all.title)
        
        app.buttons["More"].tap()
        app.buttons["Select sessions"].tap()
        app.buttons["Select All"].tap()
        XCTAssertTrue(app.buttons["Deselect All"].exists)
        XCTAssertTrue(app.buttons["Cancel"].exists)
    }
    
    func test_whenAllOtherSessionsAreSelected_navBarContainsCorrectButtons() {
        app.goToScreenWithIdentifier(MockUserOtherSessionsScreenState.all.title)
        app.buttons["More"].tap()
        app.buttons["Select sessions"].tap()
        for i in 0...MockUserOtherSessionsScreenState.all.allSessions().count - 1 {
            app.buttons["UserSessionListItem_\(i)"].tap()
        }
        XCTAssertTrue(app.buttons["Deselect All"].exists)
    }
    
    func test_whenAllOtherSessionsAreShown_learnMoreButtonIsNotShown() {
        app.goToScreenWithIdentifier(MockUserOtherSessionsScreenState.all.title)
        let button = app.buttons[VectorL10n.userSessionsOverviewOtherSessionsSectionInfo]
        let buttonLearnMore = app.buttons["\(VectorL10n.userSessionsOverviewOtherSessionsSectionInfo) + \(VectorL10n.userSessionLearnMore)"]
        XCTAssertTrue(button.exists)
        XCTAssertFalse(buttonLearnMore.exists)
    }
}
