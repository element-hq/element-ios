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

import XCTest
import RiotSwiftUI

class AuthenticationRegistrationUITests: MockScreenTest {

    override class var screenType: MockScreenState.Type {
        return MockAuthenticationRegistrationScreenState.self
    }

    override class func createTest() -> MockScreenTest {
        return AuthenticationRegistrationUITests(selector: #selector(verifyAuthenticationRegistrationScreen))
    }

    func verifyAuthenticationRegistrationScreen() throws {
        guard let screenState = screenState as? MockAuthenticationRegistrationScreenState else { fatalError("no screen") }
        switch screenState {
        case .matrixDotOrg:
            let state = "matrix.org"
            validateRegistrationFormIsVisible(for: state)
            validateSSOButtonsAreShown(for: state)
            validateFallbackButtonIsHidden(for: state)
            
            validateNoErrorsAreShown(for: state)
        case .passwordOnly:
            let state = "a password only server"
            validateRegistrationFormIsVisible(for: state)
            validateSSOButtonsAreHidden(for: state)
            validateFallbackButtonIsHidden(for: state)
            
            validateNextButtonIsDisabled(for: state)
            
            validateNoErrorsAreShown(for: state)
        case .passwordWithCredentials:
            let state = "a password only server with credentials entered"
            validateRegistrationFormIsVisible(for: state)
            validateSSOButtonsAreHidden(for: state)
            validateFallbackButtonIsHidden(for: state)
            
            validateNextButtonIsEnabled(for: state)
            
            validateNoErrorsAreShown(for: state)
        case .passwordWithUsernameError:
            let state = "a password only server with an invalid username"
            validateRegistrationFormIsVisible(for: state)
            validateSSOButtonsAreHidden(for: state)
            validateFallbackButtonIsHidden(for: state)
            
            validateNextButtonIsDisabled(for: state)
            
            validateUsernameError(for: state)
        case .ssoOnly:
            let state = "an SSO only server"
            validateRegistrationFormIsHidden(for: state)
            validateSSOButtonsAreShown(for: state)
            validateFallbackButtonIsHidden(for: state)
        case .fallback:
            let state = "fallback"
            validateRegistrationFormIsHidden(for: state)
            validateSSOButtonsAreHidden(for: state)
            validateFallbackButtonIsShown(for: state)
        }
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

    /// Checks that the fallback button is hidden.
    func validateFallbackButtonIsShown(for state: String) {
        let fallbackButton = app.buttons["fallbackButton"]

        XCTAssertTrue(fallbackButton.exists, "The fallback button should be shown for \(state).")
        XCTAssertTrue(fallbackButton.isEnabled, "The fallback button should be enabled for \(state).")
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
    
    /// Checks that neither the username or password text field footers are showing an error.
    func validateNoErrorsAreShown(for state: String) {
        let usernameFooter = textFieldFooter(for: "usernameTextField")
        let passwordFooter = textFieldFooter(for: "passwordTextField")
        
        XCTAssertTrue(usernameFooter.exists, "The username footer should be shown for \(state).")
        XCTAssertTrue(passwordFooter.exists, "The password footer should be shown for \(state).")
        XCTAssertEqual(usernameFooter.label, VectorL10n.authenticationRegistrationUsernameFooter,
                       "The username footer should be showing the default message for \(state).")
        XCTAssertEqual(passwordFooter.label, VectorL10n.authenticationRegistrationPasswordFooter,
                       "The password footer should be showing the default message for \(state).")
    }
    
    /// Gets the text field footer for the supplied identifier.
    func textFieldFooter(for identifier: String) -> XCUIElement {
        let matches = app.staticTexts.matching(identifier: identifier)
        return matches.element(boundBy: matches.count - 1)
    }
}
