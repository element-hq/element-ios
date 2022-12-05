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

class UserSessionOverviewUITests: MockScreenTestCase {
    func test_whenCurrentSessionSelected_correctNavTittleDisplayed() {
        app.goToScreenWithIdentifier(MockUserSessionOverviewScreenState.currentSession(sessionState: .unverified).title)
        let navTitle = VectorL10n.userSessionOverviewCurrentSessionTitle
        XCTAssertTrue(app.navigationBars[navTitle].staticTexts[navTitle].exists)
    }
    
    func test_whenOtherSessionSelected_correctNavTittleDisplayed() {
        app.goToScreenWithIdentifier(MockUserSessionOverviewScreenState.otherSession(sessionState: .verified).title)
        let navTitle = VectorL10n.userSessionOverviewSessionTitle
        XCTAssertTrue(app.navigationBars[navTitle].staticTexts[navTitle].exists)
    }
    
    func test_whenSessionOverviewPresented_sessionDetailsButtonExists() {
        app.goToScreenWithIdentifier(MockUserSessionOverviewScreenState.currentSession(sessionState: .unverified).title)
        XCTAssertTrue(app.buttons[VectorL10n.userSessionOverviewSessionDetailsButtonTitle].exists)
    }
    
    func test_whenSessionOverviewPresented_pusherEnabledToggleExists() {
        app.goToScreenWithIdentifier(MockUserSessionOverviewScreenState.sessionWithPushNotifications(enabled: true).title)
        XCTAssertTrue(app.switches["UserSessionOverviewToggleCell"].exists)
        XCTAssertTrue(app.switches["UserSessionOverviewToggleCell"].isOn)
        XCTAssertTrue(app.switches["UserSessionOverviewToggleCell"].isEnabled)
        XCTAssertTrue(app.staticTexts[VectorL10n.userSessionPushNotifications].exists)
        XCTAssertTrue(app.staticTexts[VectorL10n.userSessionPushNotificationsMessage].exists)
    }
    
    func test_whenSessionOverviewPresented_pusherDisabledToggleExists() {
        app.goToScreenWithIdentifier(MockUserSessionOverviewScreenState.sessionWithPushNotifications(enabled: false).title)
        XCTAssertTrue(app.switches["UserSessionOverviewToggleCell"].exists)
        XCTAssertFalse(app.switches["UserSessionOverviewToggleCell"].isOn)
        XCTAssertTrue(app.switches["UserSessionOverviewToggleCell"].isEnabled)
        XCTAssertTrue(app.staticTexts[VectorL10n.userSessionPushNotifications].exists)
        XCTAssertTrue(app.staticTexts[VectorL10n.userSessionPushNotificationsMessage].exists)
    }
    
    func test_whenSessionOverviewPresented_pusherEnabledToggleExists_remotelyTogglingPushersAvailable() {
        app.goToScreenWithIdentifier(MockUserSessionOverviewScreenState.remotelyTogglingPushersNotAvailable.title)
        XCTAssertTrue(app.switches["UserSessionOverviewToggleCell"].exists)
        XCTAssertTrue(app.switches["UserSessionOverviewToggleCell"].isOn)
        XCTAssertFalse(app.switches["UserSessionOverviewToggleCell"].isEnabled)
        XCTAssertTrue(app.staticTexts[VectorL10n.userSessionPushNotifications].exists)
        XCTAssertTrue(app.staticTexts[VectorL10n.userSessionPushNotificationsMessage].exists)
    }
    
    func test_whenSessionSelected_kebabMenuShows() {
        app.goToScreenWithIdentifier(MockUserSessionOverviewScreenState.otherSession(sessionState: .verified).title)
        let navTitle = VectorL10n.userSessionOverviewSessionTitle
        let barButton = app.navigationBars[navTitle].buttons["Menu"]
        XCTAssertTrue(barButton.exists)
        barButton.tap()
        XCTAssertTrue(app.buttons[VectorL10n.signOut].exists)
        XCTAssertTrue(app.buttons[VectorL10n.manageSessionRename].exists)
    }
    
    func test_whenOtherSessionSelected_learnMoreButtonDoesnExist() {
        let title = MockUserSessionOverviewScreenState.currentSession(sessionState: .verified).title
        app.goToScreenWithIdentifier(title)
        let buttonId = "\(VectorL10n.userOtherSessionVerifiedAdditionalInfo) \(VectorL10n.userSessionLearnMore)"
        let button = app.buttons[buttonId]
        XCTAssertFalse(button.exists)
    }
    
    func test_whenOtherVerifiedSessionSelected_learnMoreButtonExists() {
        app.goToScreenWithIdentifier(MockUserSessionOverviewScreenState.otherSession(sessionState: .verified).title)
        let buttonId = "\(VectorL10n.userOtherSessionVerifiedAdditionalInfo) \(VectorL10n.userSessionLearnMore)"
        let button = app.buttons[buttonId]
        XCTAssertTrue(button.exists)
    }
    
    func test_whenOtherUnverifiedSessionSelected_learnMoreButtonExists() {
        app.goToScreenWithIdentifier(MockUserSessionOverviewScreenState.otherSession(sessionState: .unverified).title)
        let buttonId = "\(VectorL10n.userOtherSessionUnverifiedAdditionalInfo) \(VectorL10n.userSessionLearnMore)"
        let button = app.buttons[buttonId]
        XCTAssertTrue(button.exists)
    }
    
    func test_whenPermanentlySessionSelected_copyIsCorrect() {
        app.goToScreenWithIdentifier(MockUserSessionOverviewScreenState.otherSession(sessionState: .permanentlyUnverified).title)
        let buttonId = "\(VectorL10n.userOtherSessionPermanentlyUnverifiedAdditionalInfo) \(VectorL10n.userSessionLearnMore)"
        XCTAssertTrue(app.buttons[buttonId].exists)
    }
}
