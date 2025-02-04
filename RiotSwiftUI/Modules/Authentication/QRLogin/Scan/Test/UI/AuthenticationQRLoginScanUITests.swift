//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class AuthenticationQRLoginScanUITests: MockScreenTestCase {
    func testScanning() {
        app.goToScreenWithIdentifier(MockAuthenticationQRLoginScanScreenState.scanning.title)

        XCTAssertTrue(app.staticTexts["titleLabel"].exists)
        XCTAssertTrue(app.staticTexts["subtitleLabel"].exists)
    }

    func testNoCameraAvailable() {
        app.goToScreenWithIdentifier(MockAuthenticationQRLoginScanScreenState.noCameraAvailable.title)

        XCTAssertTrue(app.staticTexts["titleLabel"].exists)
        XCTAssertTrue(app.staticTexts["subtitleLabel"].exists)

        let displayQRButton = app.buttons["displayQRButton"]
        XCTAssertTrue(displayQRButton.exists)
        XCTAssertTrue(displayQRButton.isEnabled)
    }

    func testNoCameraAccess() {
        app.goToScreenWithIdentifier(MockAuthenticationQRLoginScanScreenState.noCameraAccess.title)

        XCTAssertTrue(app.staticTexts["titleLabel"].exists)
        XCTAssertTrue(app.staticTexts["subtitleLabel"].exists)

        let openSettingsButton = app.buttons["openSettingsButton"]
        XCTAssertTrue(openSettingsButton.exists)
        XCTAssertTrue(openSettingsButton.isEnabled)

        let displayQRButton = app.buttons["displayQRButton"]
        XCTAssertTrue(displayQRButton.exists)
        XCTAssertTrue(displayQRButton.isEnabled)
    }

    func testNoCameraAvailableNoDisplayQR() {
        app.goToScreenWithIdentifier(MockAuthenticationQRLoginScanScreenState.noCameraAvailableNoDisplayQR.title)

        XCTAssertTrue(app.staticTexts["titleLabel"].exists)
        XCTAssertTrue(app.staticTexts["subtitleLabel"].exists)

        let displayQRButton = app.buttons["displayQRButton"]
        XCTAssertFalse(displayQRButton.exists)
    }

    func testNoCameraAccessNoDisplayQR() {
        app.goToScreenWithIdentifier(MockAuthenticationQRLoginScanScreenState.noCameraAccessNoDisplayQR.title)

        XCTAssertTrue(app.staticTexts["titleLabel"].exists)
        XCTAssertTrue(app.staticTexts["subtitleLabel"].exists)

        let openSettingsButton = app.buttons["openSettingsButton"]
        XCTAssertTrue(openSettingsButton.exists)
        XCTAssertTrue(openSettingsButton.isEnabled)

        let displayQRButton = app.buttons["displayQRButton"]
        XCTAssertFalse(displayQRButton.exists)
    }
}
