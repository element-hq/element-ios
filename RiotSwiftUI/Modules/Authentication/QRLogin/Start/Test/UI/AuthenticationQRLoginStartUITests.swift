//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class AuthenticationQRLoginStartUITests: MockScreenTestCase {
    func testDisplayQREnabled() {
        app.goToScreenWithIdentifier(MockAuthenticationQRLoginStartScreenState.displayQREnabled.title)

        XCTAssertTrue(app.staticTexts["titleLabel"].exists)
        XCTAssertTrue(app.staticTexts["subtitleLabel"].exists)

        let scanQRButton = app.buttons["scanQRButton"]
        XCTAssertTrue(scanQRButton.exists)
        XCTAssertTrue(scanQRButton.isEnabled)

        let displayQRButton = app.buttons["displayQRButton"]
        XCTAssertTrue(displayQRButton.exists)
        XCTAssertTrue(displayQRButton.isEnabled)
    }

    func testDisplayQRDisabled() {
        app.goToScreenWithIdentifier(MockAuthenticationQRLoginStartScreenState.displayQRDisabled.title)

        XCTAssertTrue(app.staticTexts["titleLabel"].exists)
        XCTAssertTrue(app.staticTexts["subtitleLabel"].exists)

        let scanQRButton = app.buttons["scanQRButton"]
        XCTAssertTrue(scanQRButton.exists)
        XCTAssertTrue(scanQRButton.isEnabled)

        let displayQRButton = app.buttons["displayQRButton"]
        XCTAssertFalse(displayQRButton.exists)
    }
}
