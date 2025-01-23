//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class AuthenticationQRLoginLoadingUITests: MockScreenTestCase {
    func testCommon() {
        app.goToScreenWithIdentifier(MockAuthenticationQRLoginLoadingScreenState.connectingToDevice.title)

        XCTAssertTrue(app.staticTexts["loadingLabel"].exists)

        let cancelButton = app.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.exists)
        XCTAssertTrue(cancelButton.isEnabled)
    }
}
