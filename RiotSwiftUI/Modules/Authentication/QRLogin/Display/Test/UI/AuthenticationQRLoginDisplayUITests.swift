//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class AuthenticationQRLoginDisplayUITests: MockScreenTestCase {
    func testDefault() {
        app.goToScreenWithIdentifier(MockAuthenticationQRLoginDisplayScreenState.default.title)

        XCTAssertTrue(app.staticTexts["titleLabel"].exists)
        XCTAssertTrue(app.staticTexts["subtitleLabel"].exists)
        XCTAssertTrue(app.images["qrImageView"].exists)

        let displayQRButton = app.buttons["cancelButton"]
        XCTAssertTrue(displayQRButton.exists)
        XCTAssertTrue(displayQRButton.isEnabled)
    }
}
