//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class AuthenticationLoginUITests: MockScreenTestCase {
    func testMatrixDotOrg() {
        app.goToScreenWithIdentifier(MockAuthenticationLoginScreenState.matrixDotOrg.title)
        
        let state = "matrix.org"
        validateLoginFormIsVisible(for: state)
        validateSSOButtonsAreShown(for: state)
    }
    
    func testPasswordOnly() {
        app.goToScreenWithIdentifier(MockAuthenticationLoginScreenState.passwordOnly.title)
        
        let state = "a password only server"
        validateLoginFormIsVisible(for: state)
        validateSSOButtonsAreHidden(for: state)
        
        validateNextButtonIsDisabled(for: state)
    }
    
    func testPasswordWithCredentials() {
        app.goToScreenWithIdentifier(MockAuthenticationLoginScreenState.passwordWithCredentials.title)
        
        let state = "a password only server with credentials entered"
        validateNextButtonIsEnabled(for: state)
    }
    
    func testSSOOnly() {
        app.goToScreenWithIdentifier(MockAuthenticationLoginScreenState.ssoOnly.title)
        
        let state = "an SSO only server"
        validateLoginFormIsHidden(for: state)
        validateSSOButtonsAreShown(for: state)
    }
    
    func testFallback() {
        app.goToScreenWithIdentifier(MockAuthenticationLoginScreenState.fallback.title)
        
        let state = "a fallback server"
        validateFallback(for: state)
    }
    
    /// Checks that the username and password text fields are shown along with the next button.
    func validateLoginFormIsVisible(for state: String) {
        let usernameTextField = app.textFields.element
        let passwordTextField = app.secureTextFields.element
        let nextButton = app.buttons["nextButton"]
        
        XCTAssertTrue(usernameTextField.exists, "Username input should be shown for \(state).")
        XCTAssertTrue(passwordTextField.exists, "Password input should be shown for \(state).")
        XCTAssertTrue(nextButton.exists, "The next button should be shown for \(state).")
    }
    
    /// Checks that the username and password text fields are hidden along with the next button.
    func validateLoginFormIsHidden(for state: String) {
        let usernameTextField = app.textFields.element
        let passwordTextField = app.secureTextFields.element
        let nextButton = app.buttons["nextButton"]
        
        XCTAssertFalse(usernameTextField.exists, "Username input should not be shown for \(state).")
        XCTAssertFalse(passwordTextField.exists, "Password input should not be shown for \(state).")
        XCTAssertFalse(nextButton.exists, "The next button should not be shown for \(state).")
    }
    
    /// Checks that there is at least one SSO button shown on the screen.
    func validateSSOButtonsAreShown(for state: String) {
        let ssoButtons = app.buttons.matching(identifier: "ssoButton")
        XCTAssertGreaterThan(ssoButtons.count, 0, "There should be at least 1 SSO button shown for \(state).")
    }
    
    /// Checks that no SSO buttons shown on the screen.
    func validateSSOButtonsAreHidden(for state: String) {
        let ssoButtons = app.buttons.matching(identifier: "ssoButton")
        XCTAssertEqual(ssoButtons.count, 0, "There should not be any SSO buttons shown for \(state).")
    }
    
    /// Checks that the next button is shown but is disabled.
    func validateNextButtonIsDisabled(for state: String) {
        let nextButton = app.buttons["nextButton"]
        XCTAssertTrue(nextButton.exists, "The next button should be shown.")
        XCTAssertFalse(nextButton.isEnabled, "The next button should be disabled for \(state).")
    }
    
    /// Checks that the next button is shown and is enabled.
    func validateNextButtonIsEnabled(for state: String) {
        let nextButton = app.buttons["nextButton"]
        XCTAssertTrue(nextButton.exists, "The next button should be shown.")
        XCTAssertTrue(nextButton.isEnabled, "The next button should be enabled for \(state).")
    }

    func validateFallback(for state: String) {
        let usernameTextField = app.textFields.element
        let passwordTextField = app.secureTextFields.element
        let nextButton = app.buttons["nextButton"]
        let ssoButtons = app.buttons.matching(identifier: "ssoButton")
        let fallbackButton = app.buttons["fallbackButton"]

        XCTAssertFalse(usernameTextField.exists, "Username input should not be shown for \(state).")
        XCTAssertFalse(passwordTextField.exists, "Password input should not be shown for \(state).")
        XCTAssertFalse(nextButton.exists, "The next button should not be shown for \(state).")
        XCTAssertEqual(ssoButtons.count, 0, "There should not be any SSO buttons shown for \(state).")
        XCTAssertTrue(fallbackButton.exists, "The fallback button should be shown for \(state).")
        XCTAssertTrue(fallbackButton.isEnabled, "The fallback button should be enabled for \(state).")
    }
}
