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

class AuthenticationLoginUITests: MockScreenTest {

    override class var screenType: MockScreenState.Type {
        return MockAuthenticationLoginScreenState.self
    }

    override class func createTest() -> MockScreenTest {
        return AuthenticationLoginUITests(selector: #selector(verifyAuthenticationLoginScreen))
    }
    
    func verifyAuthenticationLoginScreen() throws {
        guard let screenState = screenState as? MockAuthenticationLoginScreenState else { fatalError("no screen") }
        switch screenState {
        case .matrixDotOrg:
            let state = "matrix.org"
            validateServerDescriptionIsVisible(for: state)
            validateLoginFormIsVisible(for: state)
            validateSSOButtonsAreShown(for: state)
        case .passwordOnly:
            let state = "a password only server"
            validateServerDescriptionIsHidden(for: state)
            validateLoginFormIsVisible(for: state)
            validateSSOButtonsAreHidden(for: state)
            
            validateNextButtonIsDisabled(for: state)
        case .passwordWithCredentials:
            let state = "a password only server with credentials entered"
            validateNextButtonIsEnabled(for: state)
        case .ssoOnly:
            let state = "an SSO only server"
            validateServerDescriptionIsHidden(for: state)
            validateLoginFormIsHidden(for: state)
            validateSSOButtonsAreShown(for: state)
        case .fallback:
            let state = "a fallback server"
            validateFallback(for: state)
        }
    }
    
    /// Checks that the server description label is shown.
    func validateServerDescriptionIsVisible(for state: String) {
        let descriptionLabel = app.staticTexts["serverDescriptionText"]
        
        XCTAssertTrue(descriptionLabel.exists, "The server description should be shown for \(state).")
        XCTAssertEqual(descriptionLabel.label, VectorL10n.authenticationServerInfoMatrixDescription, "The server description should be correct for \(state).")
    }
    
    /// Checks that the server description label is hidden.
    func validateServerDescriptionIsHidden(for state: String) {
        let descriptionLabel = app.staticTexts["serverDescriptionText"]
        XCTAssertFalse(descriptionLabel.exists, "The server description should be shown for \(state).")
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
