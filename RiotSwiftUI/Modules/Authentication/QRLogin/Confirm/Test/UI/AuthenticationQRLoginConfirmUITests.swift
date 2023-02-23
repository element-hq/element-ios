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
