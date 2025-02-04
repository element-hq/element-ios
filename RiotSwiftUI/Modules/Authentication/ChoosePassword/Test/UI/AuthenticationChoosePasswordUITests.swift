//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
