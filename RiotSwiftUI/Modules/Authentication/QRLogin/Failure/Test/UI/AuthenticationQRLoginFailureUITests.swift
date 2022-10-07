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
