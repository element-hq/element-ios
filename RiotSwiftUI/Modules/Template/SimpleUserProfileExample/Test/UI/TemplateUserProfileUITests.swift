//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class TemplateUserProfileUITests: MockScreenTestCase {
    func testTemplateUserProfilePresenceIdle() {
        let presence = TemplateUserProfilePresence.idle
        app.goToScreenWithIdentifier(MockTemplateUserProfileScreenState.presence(presence).title)
        
        let presenceText = app.staticTexts["presenceText"]
        XCTAssert(presenceText.exists)
        XCTAssertEqual(presenceText.label, presence.title)
    }
    
    func testTemplateUserProfilePresenceOffline() {
        let presence = TemplateUserProfilePresence.offline
        app.goToScreenWithIdentifier(MockTemplateUserProfileScreenState.presence(presence).title)
        
        let presenceText = app.staticTexts["presenceText"]
        XCTAssert(presenceText.exists)
        XCTAssertEqual(presenceText.label, presence.title)
    }
    
    func testTemplateUserProfilePresenceOnline() {
        let presence = TemplateUserProfilePresence.online
        app.goToScreenWithIdentifier(MockTemplateUserProfileScreenState.presence(presence).title)
        
        let presenceText = app.staticTexts["presenceText"]
        XCTAssert(presenceText.exists)
        XCTAssertEqual(presenceText.label, presence.title)
    }

    func testTemplateUserProfileLongName() {
        let name = "Somebody with a super long name we would like to test"
        app.goToScreenWithIdentifier(MockTemplateUserProfileScreenState.longDisplayName(name).title)
        
        let displayNameText = app.staticTexts["displayNameText"]
        XCTAssert(displayNameText.exists)
        XCTAssertEqual(displayNameText.label, name)
    }
}
