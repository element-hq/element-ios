//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class AuthenticationQRLoginConfirmUITests: MockScreenTestCase {
    func testDefault() {
        app.goToScreenWithIdentifier(MockAuthenticationQRLoginConfirmScreenState.default.title)

        XCTAssertTrue(app.staticTexts["titleLabel"].exists)
        XCTAssertTrue(app.staticTexts["subtitleLabel"].exists)
        XCTAssertTrue(app.staticTexts["confirmationCodeLabel"].exists)
        XCTAssertTrue(app.staticTexts["alertText"].exists)

//        let confirmButton = app.buttons["confirmButton"]
//        XCTAssertTrue(confirmButton.exists)
//        XCTAssertTrue(confirmButton.isEnabled)

        let cancelButton = app.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.exists)
        XCTAssertTrue(cancelButton.isEnabled)
    }
}
