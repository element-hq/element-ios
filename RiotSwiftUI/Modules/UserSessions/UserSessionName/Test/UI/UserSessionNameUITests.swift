//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class UserSessionNameUITests: MockScreenTestCase {
    func testUserSessionNameInitialState() {
        app.goToScreenWithIdentifier(MockUserSessionNameScreenState.initialName.title)
        
        assertButtonsExists()
        let doneButton = app.buttons[VectorL10n.done]
        XCTAssertTrue(doneButton.exists)
        XCTAssertFalse(doneButton.isEnabled)
    }
    
    func testUserSessionNameEmptyState() {
        app.goToScreenWithIdentifier(MockUserSessionNameScreenState.empty.title)
        
        assertButtonsExists()
        let doneButton = app.buttons[VectorL10n.done]
        XCTAssertTrue(doneButton.exists)
        XCTAssertFalse(doneButton.isEnabled)
    }
    
    func testUserSessionNameChangedState() {
        app.goToScreenWithIdentifier(MockUserSessionNameScreenState.changedName.title)
        
        assertButtonsExists()
        let doneButton = app.buttons[VectorL10n.done]
        XCTAssertTrue(doneButton.exists)
        XCTAssertTrue(doneButton.isEnabled)
    }
}

private extension UserSessionNameUITests {
    func assertButtonsExists() {
        let buttons = [VectorL10n.done, VectorL10n.cancel, "LearnMore"]
        
        for buttonId in buttons {
            let button = app.buttons[buttonId]
            XCTAssertTrue(button.exists)
        }
    }
}
