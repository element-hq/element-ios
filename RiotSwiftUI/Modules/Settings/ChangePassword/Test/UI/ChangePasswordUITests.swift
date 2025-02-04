//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class ChangePasswordUITests: MockScreenTestCase {
    func testAllEmpty() {
        app.goToScreenWithIdentifier(MockChangePasswordScreenState.allEmpty.title)
        
        XCTAssertTrue(app.staticTexts["titleLabel"].exists, "The title should be shown.")
        XCTAssertTrue(app.staticTexts["passwordRequirementsLabel"].exists, "The password requirements label should be shown.")
        
        let oldPasswordTextField = app.secureTextFields["oldPasswordTextField"]
        XCTAssertTrue(oldPasswordTextField.exists, "The text field should be shown.")
        XCTAssertEqual(oldPasswordTextField.label, "Old password", "The text field should be showing the placeholder before text is input.")

        let newPasswordTextField1 = app.secureTextFields["newPasswordTextField1"]
        XCTAssertTrue(newPasswordTextField1.exists, "The text field should be shown.")
        XCTAssertEqual(newPasswordTextField1.label, "New password", "The text field should be showing the placeholder before text is input.")

        let newPasswordTextField2 = app.secureTextFields["newPasswordTextField2"]
        XCTAssertTrue(newPasswordTextField2.exists, "The text field should be shown.")
        XCTAssertEqual(newPasswordTextField2.label, "Confirm password", "The text field should be showing the placeholder before text is input.")
        
        let submitButton = app.buttons["submitButton"]
        XCTAssertTrue(submitButton.exists, "The submit button should be shown.")
        XCTAssertFalse(submitButton.isEnabled, "The submit button should be disabled when not able to submit.")

        let signoutAllDevicesToggle = app.switches["signoutAllDevicesToggle"]
        XCTAssertTrue(signoutAllDevicesToggle.exists, "Sign out all devices toggle should exist")
        XCTAssertFalse(signoutAllDevicesToggle.isOn, "Sign out all devices should be unchecked")
    }
    
    func testCannotSubmit() {
        app.goToScreenWithIdentifier(MockChangePasswordScreenState.cannotSubmit.title)
        
        XCTAssertTrue(app.staticTexts["titleLabel"].exists, "The title should be shown.")
        XCTAssertTrue(app.staticTexts["passwordRequirementsLabel"].exists, "The password requirements label should be shown.")

        let oldPasswordTextField = app.secureTextFields["oldPasswordTextField"]
        XCTAssertTrue(oldPasswordTextField.exists, "The text field should be shown.")
        XCTAssertEqual(oldPasswordTextField.value as? String, "••••••••", "The text field should show the entered password secretly.")

        let newPasswordTextField1 = app.secureTextFields["newPasswordTextField1"]
        XCTAssertTrue(newPasswordTextField1.exists, "The text field should be shown.")
        XCTAssertEqual(newPasswordTextField1.value as? String, "••••••••", "The text field should show the entered password secretly.")

        let newPasswordTextField2 = app.secureTextFields["newPasswordTextField2"]
        XCTAssertTrue(newPasswordTextField2.exists, "The text field should be shown.")
        XCTAssertEqual(newPasswordTextField2.label, "Confirm password", "The text field should be showing the placeholder before text is input.")

        let submitButton = app.buttons["submitButton"]
        XCTAssertTrue(submitButton.exists, "The submit button should be shown.")
        XCTAssertFalse(submitButton.isEnabled, "The submit button should be disabled when not able to submit.")

        let signoutAllDevicesToggle = app.switches["signoutAllDevicesToggle"]
        XCTAssertTrue(signoutAllDevicesToggle.exists, "Sign out all devices toggle should exist")
        XCTAssertFalse(signoutAllDevicesToggle.isOn, "Sign out all devices should be unchecked")
    }
    
    func testCanSubmit() {
        app.goToScreenWithIdentifier(MockChangePasswordScreenState.canSubmit.title)
        
        XCTAssertTrue(app.staticTexts["titleLabel"].exists, "The title should be shown.")
        XCTAssertTrue(app.staticTexts["passwordRequirementsLabel"].exists, "The password requirements label should be shown.")

        let oldPasswordTextField = app.secureTextFields["oldPasswordTextField"]
        XCTAssertTrue(oldPasswordTextField.exists, "The text field should be shown.")
        XCTAssertEqual(oldPasswordTextField.value as? String, "••••••••", "The text field should show the entered password secretly.")

        let newPasswordTextField1 = app.secureTextFields["newPasswordTextField1"]
        XCTAssertTrue(newPasswordTextField1.exists, "The text field should be shown.")
        XCTAssertEqual(newPasswordTextField1.value as? String, "••••••••", "The text field should show the entered password secretly.")

        let newPasswordTextField2 = app.secureTextFields["newPasswordTextField2"]
        XCTAssertTrue(newPasswordTextField2.exists, "The text field should be shown.")
        XCTAssertEqual(newPasswordTextField2.value as? String, "••••••••", "The text field should show the entered password secretly.")

        let submitButton = app.buttons["submitButton"]
        XCTAssertTrue(submitButton.exists, "The submit button should be shown.")
        XCTAssertTrue(submitButton.isEnabled, "The submit button should be enabled when able to submit.")

        let signoutAllDevicesToggle = app.switches["signoutAllDevicesToggle"]
        XCTAssertTrue(signoutAllDevicesToggle.exists, "Sign out all devices toggle should exist")
        XCTAssertFalse(signoutAllDevicesToggle.isOn, "Sign out all devices should be unchecked")
    }

    func testCanSubmitAndSignoutAllDevicesChecked() {
        app.goToScreenWithIdentifier(MockChangePasswordScreenState.canSubmitAndSignoutAllDevicesChecked.title)
        
        XCTAssertTrue(app.staticTexts["titleLabel"].exists, "The title should be shown.")
        XCTAssertTrue(app.staticTexts["passwordRequirementsLabel"].exists, "The password requirements label should be shown.")

        let oldPasswordTextField = app.secureTextFields["oldPasswordTextField"]
        XCTAssertTrue(oldPasswordTextField.exists, "The text field should be shown.")
        XCTAssertEqual(oldPasswordTextField.value as? String, "••••••••", "The text field should show the entered password secretly.")

        let newPasswordTextField1 = app.secureTextFields["newPasswordTextField1"]
        XCTAssertTrue(newPasswordTextField1.exists, "The text field should be shown.")
        XCTAssertEqual(newPasswordTextField1.value as? String, "••••••••", "The text field should show the entered password secretly.")

        let newPasswordTextField2 = app.secureTextFields["newPasswordTextField2"]
        XCTAssertTrue(newPasswordTextField2.exists, "The text field should be shown.")
        XCTAssertEqual(newPasswordTextField2.value as? String, "••••••••", "The text field should show the entered password secretly.")

        let submitButton = app.buttons["submitButton"]
        XCTAssertTrue(submitButton.exists, "The submit button should be shown.")
        XCTAssertTrue(submitButton.isEnabled, "The submit button should be enabled when able to submit.")

        let signoutAllDevicesToggle = app.switches["signoutAllDevicesToggle"]
        XCTAssertTrue(signoutAllDevicesToggle.exists, "Sign out all devices toggle should exist")
        XCTAssertTrue(signoutAllDevicesToggle.isOn, "Sign out all devices should be checked")
    }
}
