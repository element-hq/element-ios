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
