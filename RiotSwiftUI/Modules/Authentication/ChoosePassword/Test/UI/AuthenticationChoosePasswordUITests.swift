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

class AuthenticationChoosePasswordUITests: MockScreenTestCase {
    func testEmptyPassword() {
        app.goToScreenWithIdentifier(MockAuthenticationChoosePasswordScreenState.emptyPassword.title)
        
        XCTAssertTrue(app.staticTexts["titleLabel"].exists, "The title should be shown.")
        XCTAssertTrue(app.staticTexts["messageLabel"].exists, "The message should be shown.")
        
        let passwordTextField = app.secureTextFields["passwordTextField"]
        XCTAssertTrue(passwordTextField.exists, "The text field should be shown.")
        XCTAssertEqual(passwordTextField.label, "New Password", "The text field should be showing the placeholder before text is input.")
        
        let submitButton = app.buttons["submitButton"]
        XCTAssertTrue(submitButton.exists, "The submit button should be shown.")
        XCTAssertFalse(submitButton.isEnabled, "The submit button should be disabled before text is input.")

        let signoutAllDevicesToggle = app.switches["signoutAllDevicesToggle"]
        XCTAssertTrue(signoutAllDevicesToggle.exists, "Sign out all devices toggle should exist")
        XCTAssertFalse(signoutAllDevicesToggle.isOn, "Sign out all devices should be unchecked")
    }
    
    func testEnteredInvalidPassword() {
        app.goToScreenWithIdentifier(MockAuthenticationChoosePasswordScreenState.enteredInvalidPassword.title)
        
        XCTAssertTrue(app.staticTexts["titleLabel"].exists, "The title should be shown.")
        XCTAssertTrue(app.staticTexts["messageLabel"].exists, "The message should be shown.")

        let passwordTextField = app.secureTextFields["passwordTextField"]
        XCTAssertTrue(passwordTextField.exists, "The text field should be shown.")
        XCTAssertEqual(passwordTextField.value as? String, "••••", "The text field should be showing the placeholder before text is input.")

        let submitButton = app.buttons["submitButton"]
        XCTAssertTrue(submitButton.exists, "The submit button should be shown.")
        XCTAssertFalse(submitButton.isEnabled, "The submit button should be disabled when password is invalid.")

        let signoutAllDevicesToggle = app.switches["signoutAllDevicesToggle"]
        XCTAssertTrue(signoutAllDevicesToggle.exists, "Sign out all devices toggle should exist")
        XCTAssertFalse(signoutAllDevicesToggle.isOn, "Sign out all devices should be unchecked")
    }
    
    func testEnteredValidPassword() {
        app.goToScreenWithIdentifier(MockAuthenticationChoosePasswordScreenState.enteredValidPassword.title)
        
        XCTAssertTrue(app.staticTexts["titleLabel"].exists, "The title should be shown.")
        XCTAssertTrue(app.staticTexts["messageLabel"].exists, "The message should be shown.")

        let passwordTextField = app.secureTextFields["passwordTextField"]
        XCTAssertTrue(passwordTextField.exists, "The text field should be shown.")
        XCTAssertEqual(passwordTextField.value as? String, "••••••••", "The text field should be showing the placeholder before text is input.")

        let submitButton = app.buttons["submitButton"]
        XCTAssertTrue(submitButton.exists, "The submit button should be shown.")
        XCTAssertTrue(submitButton.isEnabled, "The submit button should be enabled after password is valid.")

        let signoutAllDevicesToggle = app.switches["signoutAllDevicesToggle"]
        XCTAssertTrue(signoutAllDevicesToggle.exists, "Sign out all devices toggle should exist")
        XCTAssertFalse(signoutAllDevicesToggle.isOn, "Sign out all devices should be unchecked")
    }

    func testEnteredValidPasswordAndSignoutAllDevicesChecked() {
        app.goToScreenWithIdentifier(MockAuthenticationChoosePasswordScreenState.enteredValidPasswordAndSignoutAllDevicesChecked.title)
        
        XCTAssertTrue(app.staticTexts["titleLabel"].exists, "The title should be shown.")
        XCTAssertTrue(app.staticTexts["messageLabel"].exists, "The message should be shown.")

        let passwordTextField = app.secureTextFields["passwordTextField"]
        XCTAssertTrue(passwordTextField.exists, "The text field should be shown.")
        XCTAssertEqual(passwordTextField.value as? String, "••••••••", "The text field should be showing the placeholder before text is input.")

        let submitButton = app.buttons["submitButton"]
        XCTAssertTrue(submitButton.exists, "The submit button should be shown.")
        XCTAssertTrue(submitButton.isEnabled, "The submit button should be enabled after password is valid.")

        let signoutAllDevicesToggle = app.switches["signoutAllDevicesToggle"]
        XCTAssertTrue(signoutAllDevicesToggle.exists, "Sign out all devices toggle should exist")
        XCTAssertTrue(signoutAllDevicesToggle.isOn, "Sign out all devices should be checked")
    }
}

extension XCUIElement {
    var isOn: Bool {
        (value as? String) == "1"
    }
}
