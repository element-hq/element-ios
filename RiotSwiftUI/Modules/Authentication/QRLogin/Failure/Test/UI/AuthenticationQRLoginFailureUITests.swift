//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class AuthenticationQRLoginFailureUITests: MockScreenTestCase {
    func testInvalidQR() {
        app.goToScreenWithIdentifier(MockAuthenticationQRLoginFailureScreenState.invalidQR.title)

        XCTAssertTrue(app.staticTexts["failureLabel"].exists)

        let retryButton = app.buttons["retryButton"]
        XCTAssertTrue(retryButton.exists)
        XCTAssertTrue(retryButton.isEnabled)

        let cancelButton = app.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.exists)
        XCTAssertTrue(cancelButton.isEnabled)
    }

    func testDeviceNotSupported() {
        app.goToScreenWithIdentifier(MockAuthenticationQRLoginFailureScreenState.deviceNotSupported.title)

        XCTAssertTrue(app.staticTexts["failureLabel"].exists)

        let retryButton = app.buttons["retryButton"]
        XCTAssertTrue(retryButton.exists)
        XCTAssertTrue(retryButton.isEnabled)

        let cancelButton = app.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.exists)
        XCTAssertTrue(cancelButton.isEnabled)
    }

    func testRequestDenied() {
        app.goToScreenWithIdentifier(MockAuthenticationQRLoginFailureScreenState.requestDenied.title)

        XCTAssertTrue(app.staticTexts["failureLabel"].exists)

        let retryButton = app.buttons["retryButton"]
        XCTAssertFalse(retryButton.exists)

        let cancelButton = app.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.exists)
        XCTAssertTrue(cancelButton.isEnabled)
    }

    func testRequestTimedOut() {
        app.goToScreenWithIdentifier(MockAuthenticationQRLoginFailureScreenState.requestTimedOut.title)

        XCTAssertTrue(app.staticTexts["failureLabel"].exists)

        let retryButton = app.buttons["retryButton"]
        XCTAssertTrue(retryButton.exists)
        XCTAssertTrue(retryButton.isEnabled)

        let cancelButton = app.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.exists)
        XCTAssertTrue(cancelButton.isEnabled)
    }
}
