//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class AuthenticationForgotPasswordUITests: MockScreenTestCase {
    func testEmptyAddress() {
        app.goToScreenWithIdentifier(MockAuthenticationForgotPasswordScreenState.emptyAddress.title)
        
        XCTAssertTrue(app.staticTexts["titleLabel"].exists, "The title should be shown before an email is sent.")
        XCTAssertTrue(app.staticTexts["messageLabel"].exists, "The message should be shown before an email is sent.")
        
        let addressTextField = app.textFields["addressTextField"]
        XCTAssertTrue(addressTextField.exists, "The text field should be shown before an email is sent.")
        XCTAssertEqual(addressTextField.value as? String, VectorL10n.authenticationForgotPasswordTextFieldPlaceholder,
                       "The text field should be showing the placeholder before text is input.")
        
        let nextButton = app.buttons["nextButton"]
        XCTAssertTrue(nextButton.exists, "The next button should be shown before an email is sent.")
        XCTAssertFalse(nextButton.isEnabled, "The next button should be disabled before text is input.")

        let doneButton = app.buttons["doneButton"]
        XCTAssertFalse(doneButton.exists, "The done button should be hidden before an email has been sent.")

        let resendButton = app.buttons["resendButton"]
        XCTAssertFalse(resendButton.exists, "The done button should be hidden before an email has been sent.")
        
        XCTAssertFalse(app.staticTexts["waitingTitleLabel"].exists, "The waiting title should be hidden until an email is sent.")
        XCTAssertFalse(app.staticTexts["waitingMessageLabel"].exists, "The waiting message should be hidden until an email is sent.")

        let cancelButton = app.navigationBars.firstMatch.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should be shown.")
        XCTAssertEqual(cancelButton.label, "Cancel")
    }
    
    func testEnteredAddress() {
        app.goToScreenWithIdentifier(MockAuthenticationForgotPasswordScreenState.enteredAddress.title)
        
        XCTAssertTrue(app.staticTexts["titleLabel"].exists, "The title should be shown before an email is sent.")
        XCTAssertTrue(app.staticTexts["messageLabel"].exists, "The message should be shown before an email is sent.")
        
        let addressTextField = app.textFields["addressTextField"]
        XCTAssertTrue(addressTextField.exists, "The text field should be shown before an email is sent.")
        XCTAssertEqual(addressTextField.value as? String, "test@example.com", "The text field should show the email address that was input.")
        
        let nextButton = app.buttons["nextButton"]
        XCTAssertTrue(nextButton.exists, "The next button should be shown before an email is sent.")
        XCTAssertTrue(nextButton.isEnabled, "The next button should be enabled once an address has been input.")

        let doneButton = app.buttons["doneButton"]
        XCTAssertFalse(doneButton.exists, "The done button should be hidden before an email has been sent.")

        let resendButton = app.buttons["resendButton"]
        XCTAssertFalse(resendButton.exists, "The done button should be hidden before an email has been sent.")
        
        XCTAssertFalse(app.staticTexts["waitingTitleLabel"].exists, "The waiting title should be hidden until an email is sent.")
        XCTAssertFalse(app.staticTexts["waitingMessageLabel"].exists, "The waiting message should be hidden until an email is sent.")

        let cancelButton = app.navigationBars.firstMatch.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should be shown.")
        XCTAssertEqual(cancelButton.label, "Cancel")
    }
    
    func testWaitingForEmailLink() {
        app.goToScreenWithIdentifier(MockAuthenticationForgotPasswordScreenState.hasSentEmail.title)
        
        XCTAssertFalse(app.staticTexts["titleLabel"].exists, "The title should be hidden once an email has been sent.")
        XCTAssertFalse(app.staticTexts["messageLabel"].exists, "The message should be hidden once an email has been sent.")
        XCTAssertFalse(app.textFields["addressTextField"].exists, "The text field should be hidden once an email has been sent.")
        XCTAssertFalse(app.buttons["nextButton"].exists, "The next button should be hidden once an email has been sent.")

        let doneButton = app.buttons["doneButton"]
        XCTAssertTrue(doneButton.exists, "The done button should be hidden once an email has been sent.")
        XCTAssertTrue(doneButton.isEnabled)

        let resendButton = app.buttons["resendButton"]
        XCTAssertTrue(resendButton.exists, "The resend button should be hidden once an email has been sent.")
        XCTAssertTrue(resendButton.isEnabled)
        
        XCTAssertTrue(app.staticTexts["waitingTitleLabel"].exists, "The waiting title should be shown once an email has been sent.")
        XCTAssertTrue(app.staticTexts["waitingMessageLabel"].exists, "The waiting title should be shown once an email has been sent.")

        let backButton = app.navigationBars.firstMatch.buttons["cancelButton"]
        XCTAssertTrue(backButton.exists, "Back button should be shown.")
        XCTAssertEqual(backButton.label, "Back")
    }
}
