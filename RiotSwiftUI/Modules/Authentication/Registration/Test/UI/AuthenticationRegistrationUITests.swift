//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class AuthenticationRegistrationUITests: MockScreenTestCase {
    func testMatrixDotOrg() {
        app.goToScreenWithIdentifier(MockAuthenticationRegistrationScreenState.matrixDotOrg.title)
        
        let state = "matrix.org"
        validateRegistrationFormIsVisible(for: state)
        validateSSOButtonsAreShown(for: state)
        validateSunsetBannersAreHidden(for: state)
        validateFallbackButtonIsHidden(for: state)
        
        validateUnknownUsernameAvailability(for: state)
        validateNoPasswordErrorsAreShown(for: state)
    }
    
    func testPasswordOnly() {
        app.goToScreenWithIdentifier(MockAuthenticationRegistrationScreenState.passwordOnly.title)
        
        let state = "a password only server"
        validateRegistrationFormIsVisible(for: state)
        validateSSOButtonsAreHidden(for: state)
        validateSunsetBannersAreHidden(for: state)
        validateFallbackButtonIsHidden(for: state)
        
        validateNextButtonIsDisabled(for: state)
        
        validateUnknownUsernameAvailability(for: state)
        validateNoPasswordErrorsAreShown(for: state)
    }
    
    func testPasswordWithCredentials() {
        app.goToScreenWithIdentifier(MockAuthenticationRegistrationScreenState.passwordWithCredentials.title)
        
        let state = "a password only server with credentials entered"
        validateRegistrationFormIsVisible(for: state)
        validateSSOButtonsAreHidden(for: state)
        validateSunsetBannersAreHidden(for: state)
        validateFallbackButtonIsHidden(for: state)
        
        validateNextButtonIsEnabled(for: state)
        
        validateUsernameAvailable(for: state)
        validateNoPasswordErrorsAreShown(for: state)
    }
    
    func testPasswordWithUsernameError() {
        app.goToScreenWithIdentifier(MockAuthenticationRegistrationScreenState.passwordWithUsernameError.title)
        
        let state = "a password only server with an invalid username"
        validateRegistrationFormIsVisible(for: state)
        validateSSOButtonsAreHidden(for: state)
        validateSunsetBannersAreHidden(for: state)
        validateFallbackButtonIsHidden(for: state)
        
        validateNextButtonIsDisabled(for: state)
        validateUsernameError(for: state)
    }
    
    func testSSOOnly() {
        app.goToScreenWithIdentifier(MockAuthenticationRegistrationScreenState.ssoOnly.title)
        
        let state = "an SSO only server"
        validateRegistrationFormIsHidden(for: state)
        validateSSOButtonsAreShown(for: state)
        validateSunsetBannersAreHidden(for: state)
        validateFallbackButtonIsHidden(for: state)
    }
    
    func testFallback() {
        app.goToScreenWithIdentifier(MockAuthenticationRegistrationScreenState.fallback.title)
        
        let state = "fallback"
        validateRegistrationFormIsHidden(for: state)
        validateSSOButtonsAreHidden(for: state)
        validateSunsetBannersAreHidden(for: state)
        validateFallbackButtonIsShown(for: state)
    }
    
    func testSunsetBanner() {
        app.goToScreenWithIdentifier(MockAuthenticationRegistrationScreenState.mas.title)
        
        let state = "mas"
        validateRegistrationFormIsHidden(for: state)
        validateSSOButtonsAreHidden(for: state)
        validateSunsetBannersAreShown(for: state)
        validateFallbackButtonIsShown(for: state, isEnabled: false)
    }
    
    /// Checks that the username and password text fields are shown along with the next button.
    func validateRegistrationFormIsVisible(for state: String) {
        let usernameTextField = app.textFields.element
        let passwordTextField = app.secureTextFields.element
        let nextButton = app.buttons["nextButton"]
        
        XCTAssertTrue(usernameTextField.exists, "Username input should be shown for \(state).")
        XCTAssertTrue(passwordTextField.exists, "Password input should be shown for \(state).")
        XCTAssertTrue(nextButton.exists, "The next button should be shown for \(state).")
    }
    
    /// Checks that the username and password text fields are hidden along with the next button.
    func validateRegistrationFormIsHidden(for state: String) {
        let usernameTextField = app.textFields.element
        let passwordTextField = app.secureTextFields.element
        let nextButton = app.buttons["nextButton"]
        
        XCTAssertFalse(usernameTextField.exists, "Username input should not be shown for \(state).")
        XCTAssertFalse(passwordTextField.exists, "Password input should not be shown for \(state).")
        XCTAssertFalse(nextButton.exists, "The next button should not be shown for \(state).")
    }

    /// Checks that the fallback button is hidden.
    func validateFallbackButtonIsHidden(for state: String) {
        let fallbackButton = app.buttons["fallbackButton"]

        XCTAssertFalse(fallbackButton.exists, "The fallback button should not be shown for \(state).")
    }

    /// Checks that the fallback button is shown.
    func validateFallbackButtonIsShown(for state: String, isEnabled: Bool = true) {
        let fallbackButton = app.buttons["fallbackButton"]

        XCTAssertTrue(fallbackButton.exists, "The fallback button should be shown for \(state).")
        XCTAssertEqual(fallbackButton.isEnabled, isEnabled, "The fallback button should be \(isEnabled ? "enabled" : "disabled") for \(state).")
    }
    
    /// Checks that the sunset banners are hidden.
    func validateSunsetBannersAreHidden(for state: String) {
        let downloadBanner = app.buttons["sunsetBanners"]

        XCTAssertFalse(downloadBanner.exists, "The sunset banners should not be shown for \(state).")
    }

    /// Checks that the sunset banners are shown.
    func validateSunsetBannersAreShown(for state: String) {
        let downloadBanner = app.buttons["sunsetBanners"]

        XCTAssertTrue(downloadBanner.exists, "The sunset banners should be shown for \(state).")
        XCTAssertTrue(downloadBanner.isEnabled, "The sunset banners should be enabled for \(state).")
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
    
    /// Checks that the username text field footer is showing an error.
    func validateUsernameError(for state: String) {
        let usernameFooter = textFieldFooter(for: "usernameTextField")
        XCTAssertTrue(usernameFooter.exists, "The username footer should be shown for \(state).")
        XCTAssertEqual(usernameFooter.label, VectorL10n.authInvalidUserName, "The username footer should be showing an error for \(state).")
    }
    
    func validateUsernameAvailable(for state: String) {
        let usernameFooter = textFieldFooter(for: "usernameTextField")
        XCTAssertTrue(usernameFooter.exists, "The username footer should be shown for \(state).")
        XCTAssertTrue(usernameFooter.label.starts(with: VectorL10n.authenticationRegistrationUsernameFooterAvailable("")),
                      "The username footer should be showing the username as available for \(state).")
    }
    
    func validateUnknownUsernameAvailability(for state: String) {
        let usernameFooter = textFieldFooter(for: "usernameTextField")
        XCTAssertTrue(usernameFooter.exists, "The username footer should be shown for \(state).")
        XCTAssertEqual(usernameFooter.label, VectorL10n.authenticationRegistrationUsernameFooter,
                       "The username footer should be showing the default message for \(state).")
    }
    
    /// Checks that neither the username or password text field footers are showing an error.
    func validateNoPasswordErrorsAreShown(for state: String) {
        let passwordFooter = textFieldFooter(for: "passwordTextField")
        XCTAssertTrue(passwordFooter.exists, "The password footer should be shown for \(state).")
        XCTAssertEqual(passwordFooter.label, VectorL10n.authenticationRegistrationPasswordFooter,
                       "The password footer should be showing the default message for \(state).")
    }
    
    /// Gets the text field footer for the supplied identifier.
    func textFieldFooter(for identifier: String) -> XCUIElement {
        let matches = app.staticTexts.matching(identifier: identifier)
        return matches.element(boundBy: matches.count - 1)
    }
}
