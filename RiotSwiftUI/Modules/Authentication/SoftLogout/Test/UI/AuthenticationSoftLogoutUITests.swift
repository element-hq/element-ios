//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class AuthenticationSoftLogoutUITests: MockScreenTestCase {
    func testEmptyPassword() {
        app.goToScreenWithIdentifier(MockAuthenticationSoftLogoutScreenState.emptyPassword.title)
        
        XCTAssertTrue(app.staticTexts["titleLabel"].exists, "The title should be shown.")
        XCTAssertTrue(app.staticTexts["messageLabel1"].exists, "The message 1 should be shown.")
        XCTAssertTrue(app.staticTexts["messageLabel2"].exists, "The message 2 should be shown.")
        XCTAssertTrue(app.staticTexts["clearDataTitleLabel"].exists, "The clear data title should be shown.")
        XCTAssertTrue(app.staticTexts["clearDataMessage1Label"].exists, "The clear data message 1 should be shown.")
        XCTAssertTrue(app.staticTexts["clearDataMessage2Label"].exists, "The clear data message 2 should be shown.")
        XCTAssertTrue(app.staticTexts["orLabel"].exists, "The or label for SSO should be shown.")
        
        let passwordTextField = app.secureTextFields["passwordTextField"]
        XCTAssertTrue(passwordTextField.exists, "The password text field should be shown.")
        XCTAssertEqual(passwordTextField.label, "Password", "The password text field should be showing the placeholder before text is input.")
        
        let loginButton = app.buttons["loginButton"]
        XCTAssertTrue(loginButton.exists, "The login button should be shown.")
        XCTAssertFalse(loginButton.isEnabled, "The login button should be disabled before text is input.")

        let forgotPasswordButton = app.buttons["forgotPasswordButton"]
        XCTAssertTrue(forgotPasswordButton.exists, "The forgot password button should be shown.")
        XCTAssertTrue(forgotPasswordButton.isEnabled, "The forgot password button should be enabled.")

        let fallbackButton = app.buttons["fallbackButton"]
        XCTAssertFalse(fallbackButton.exists, "The fallback button should not be shown.")

        let clearDataButton = app.buttons["clearDataButton"]
        XCTAssertTrue(clearDataButton.exists, "The clear data button should be shown.")
        XCTAssertTrue(clearDataButton.isEnabled, "The clear data button should be enabled.")

        let ssoButtons = app.buttons.matching(identifier: "ssoButton")
        XCTAssertGreaterThan(ssoButtons.count, 0, "There should be at least 1 SSO button shown.")
    }

    func testEnteredPassword() {
        app.goToScreenWithIdentifier(MockAuthenticationSoftLogoutScreenState.enteredPassword.title)
        
        XCTAssertTrue(app.staticTexts["titleLabel"].exists, "The title should be shown.")
        XCTAssertTrue(app.staticTexts["messageLabel1"].exists, "The message 1 should be shown.")
        XCTAssertTrue(app.staticTexts["messageLabel2"].exists, "The message 2 should be shown.")
        XCTAssertTrue(app.staticTexts["clearDataTitleLabel"].exists, "The clear data title should be shown.")
        XCTAssertTrue(app.staticTexts["clearDataMessage1Label"].exists, "The clear data message 1 should be shown.")
        XCTAssertTrue(app.staticTexts["clearDataMessage2Label"].exists, "The clear data message 2 should be shown.")
        XCTAssertTrue(app.staticTexts["orLabel"].exists, "The or label for SSO should be shown.")

        let passwordTextField = app.secureTextFields["passwordTextField"]
        XCTAssertTrue(passwordTextField.exists, "The password text field should be shown.")
        XCTAssertEqual(passwordTextField.value as? String, "••••••••", "The text field should be showing the placeholder before text is input.")

        let loginButton = app.buttons["loginButton"]
        XCTAssertTrue(loginButton.exists, "The login button should be shown.")
        XCTAssertTrue(loginButton.isEnabled, "The login button should be enabled after text is input.")

        let forgotPasswordButton = app.buttons["forgotPasswordButton"]
        XCTAssertTrue(forgotPasswordButton.exists, "The forgot password button should be shown.")
        XCTAssertTrue(forgotPasswordButton.isEnabled, "The forgot password button should be enabled.")

        let fallbackButton = app.buttons["fallbackButton"]
        XCTAssertFalse(fallbackButton.exists, "The fallback button should not be shown.")

        let clearDataButton = app.buttons["clearDataButton"]
        XCTAssertTrue(clearDataButton.exists, "The clear data button should be shown.")
        XCTAssertTrue(clearDataButton.isEnabled, "The clear data button should be enabled.")

        let ssoButtons = app.buttons.matching(identifier: "ssoButton")
        XCTAssertGreaterThan(ssoButtons.count, 0, "There should be at least 1 SSO button shown.")
    }

    func testSSOOnly() {
        app.goToScreenWithIdentifier(MockAuthenticationSoftLogoutScreenState.ssoOnly.title)
        
        XCTAssertTrue(app.staticTexts["titleLabel"].exists, "The title should be shown.")
        XCTAssertTrue(app.staticTexts["messageLabel1"].exists, "The message 1 should be shown.")
        XCTAssertTrue(app.staticTexts["messageLabel2"].exists, "The message 2 should be shown.")
        XCTAssertTrue(app.staticTexts["clearDataTitleLabel"].exists, "The clear data title should be shown.")
        XCTAssertTrue(app.staticTexts["clearDataMessage1Label"].exists, "The clear data message 1 should be shown.")
        XCTAssertTrue(app.staticTexts["clearDataMessage2Label"].exists, "The clear data message 2 should be shown.")
        XCTAssertTrue(app.staticTexts["orLabel"].exists, "The or label for SSO should be shown.")

        let passwordTextField = app.secureTextFields["passwordTextField"]
        XCTAssertFalse(passwordTextField.exists, "The password text field should not be shown.")

        let loginButton = app.buttons["loginButton"]
        XCTAssertFalse(loginButton.exists, "The login button should not be shown.")

        let forgotPasswordButton = app.buttons["forgotPasswordButton"]
        XCTAssertFalse(forgotPasswordButton.exists, "The forgot password button should not be shown.")

        let fallbackButton = app.buttons["fallbackButton"]
        XCTAssertFalse(fallbackButton.exists, "The fallback button should not be shown.")

        let clearDataButton = app.buttons["clearDataButton"]
        XCTAssertTrue(clearDataButton.exists, "The clear data button should be shown.")
        XCTAssertTrue(clearDataButton.isEnabled, "The clear data button should be enabled.")

        let ssoButtons = app.buttons.matching(identifier: "ssoButton")
        XCTAssertGreaterThan(ssoButtons.count, 0, "There should be at least 1 SSO button shown.")
    }

    func testNoSSO() {
        app.goToScreenWithIdentifier(MockAuthenticationSoftLogoutScreenState.noSSO.title)
        
        XCTAssertTrue(app.staticTexts["titleLabel"].exists, "The title should be shown.")
        XCTAssertTrue(app.staticTexts["messageLabel1"].exists, "The message 1 should be shown.")
        XCTAssertTrue(app.staticTexts["messageLabel2"].exists, "The message 2 should be shown.")
        XCTAssertTrue(app.staticTexts["clearDataTitleLabel"].exists, "The clear data title should be shown.")
        XCTAssertTrue(app.staticTexts["clearDataMessage1Label"].exists, "The clear data message 1 should be shown.")
        XCTAssertTrue(app.staticTexts["clearDataMessage2Label"].exists, "The clear data message 2 should be shown.")
        XCTAssertFalse(app.staticTexts["orLabel"].exists, "The or label for SSO should not be shown.")

        let passwordTextField = app.secureTextFields["passwordTextField"]
        XCTAssertTrue(passwordTextField.exists, "The password text field should be shown.")

        let loginButton = app.buttons["loginButton"]
        XCTAssertTrue(loginButton.exists, "The login button should be shown.")

        let forgotPasswordButton = app.buttons["forgotPasswordButton"]
        XCTAssertTrue(forgotPasswordButton.exists, "The forgot password button should be shown.")

        let fallbackButton = app.buttons["fallbackButton"]
        XCTAssertFalse(fallbackButton.exists, "The fallback button should not be shown.")

        let clearDataButton = app.buttons["clearDataButton"]
        XCTAssertTrue(clearDataButton.exists, "The clear data button should be shown.")
        XCTAssertTrue(clearDataButton.isEnabled, "The clear data button should be enabled.")

        let ssoButtons = app.buttons.matching(identifier: "ssoButton")
        XCTAssertEqual(ssoButtons.count, 0, "There should be no SSO button shown.")
    }

    func testFallback() {
        app.goToScreenWithIdentifier(MockAuthenticationSoftLogoutScreenState.fallback.title)
        
        XCTAssertTrue(app.staticTexts["titleLabel"].exists, "The title should be shown.")
        XCTAssertTrue(app.staticTexts["messageLabel1"].exists, "The message 1 should be shown.")
        XCTAssertTrue(app.staticTexts["messageLabel2"].exists, "The message 2 should be shown.")
        XCTAssertTrue(app.staticTexts["clearDataTitleLabel"].exists, "The clear data title should be shown.")
        XCTAssertTrue(app.staticTexts["clearDataMessage1Label"].exists, "The clear data message 1 should be shown.")
        XCTAssertTrue(app.staticTexts["clearDataMessage2Label"].exists, "The clear data message 2 should be shown.")
        XCTAssertFalse(app.staticTexts["orLabel"].exists, "The or label for SSO should not be shown.")

        let passwordTextField = app.secureTextFields["passwordTextField"]
        XCTAssertFalse(passwordTextField.exists, "The password text field should not be shown.")

        let loginButton = app.buttons["loginButton"]
        XCTAssertFalse(loginButton.exists, "The login button should not be shown.")

        let forgotPasswordButton = app.buttons["forgotPasswordButton"]
        XCTAssertFalse(forgotPasswordButton.exists, "The forgot password button should not be shown.")

        let fallbackButton = app.buttons["fallbackButton"]
        XCTAssertTrue(fallbackButton.exists, "The fallback button should be shown.")
        XCTAssertTrue(fallbackButton.isEnabled, "The fallback button should be enabled.")

        let clearDataButton = app.buttons["clearDataButton"]
        XCTAssertTrue(clearDataButton.exists, "The clear data button should be shown.")
        XCTAssertTrue(clearDataButton.isEnabled, "The clear data button should be enabled.")

        let ssoButtons = app.buttons.matching(identifier: "ssoButton")
        XCTAssertEqual(ssoButtons.count, 0, "There should be no SSO button shown.")
    }

    func testNoKeyBackup() {
        app.goToScreenWithIdentifier(MockAuthenticationSoftLogoutScreenState.noKeyBackup.title)
        
        XCTAssertFalse(app.staticTexts["messageLabel2"].exists, "The message 2 should not be shown.")
    }
}
