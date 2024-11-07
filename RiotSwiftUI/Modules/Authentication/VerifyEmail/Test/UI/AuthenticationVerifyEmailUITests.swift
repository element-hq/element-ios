//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class AuthenticationVerifyEmailUITests: MockScreenTestCase {
    func testEmptyAddress() {
        app.goToScreenWithIdentifier(MockAuthenticationVerifyEmailScreenState.emptyAddress.title)
        
        XCTAssertTrue(app.staticTexts["titleLabel"].exists, "The title should be shown before an email is sent.")
        XCTAssertTrue(app.staticTexts["messageLabel"].exists, "The message should be shown before an email is sent.")
        
        let addressTextField = app.textFields["addressTextField"]
        XCTAssertTrue(addressTextField.exists, "The text field should be shown before an email is sent.")
        XCTAssertEqual(addressTextField.value as? String, VectorL10n.authenticationVerifyEmailTextFieldPlaceholder,
                       "The text field should be showing the placeholder before text is input.")
        
        let nextButton = app.buttons["nextButton"]
        XCTAssertTrue(nextButton.exists, "The next button should be shown before an email is sent.")
        XCTAssertFalse(nextButton.isEnabled, "The next button should be disabled before text is input.")
        
        XCTAssertFalse(app.staticTexts["waitingTitleLabel"].exists, "The waiting title should be hidden until an email is sent.")
        XCTAssertFalse(app.staticTexts["waitingMessageLabel"].exists, "The waiting message should be hidden until an email is sent.")

        let cancelButton = app.navigationBars.firstMatch.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should be shown.")
        XCTAssertEqual(cancelButton.label, "Cancel")
    }
    
    func testEnteredAddress() {
        app.goToScreenWithIdentifier(MockAuthenticationVerifyEmailScreenState.enteredAddress.title)
        
        XCTAssertTrue(app.staticTexts["titleLabel"].exists, "The title should be shown before an email is sent.")
        XCTAssertTrue(app.staticTexts["messageLabel"].exists, "The message should be shown before an email is sent.")
        
        let addressTextField = app.textFields["addressTextField"]
        XCTAssertTrue(addressTextField.exists, "The text field should be shown before an email is sent.")
        XCTAssertEqual(addressTextField.value as? String, "test@example.com", "The text field should show the email address that was input.")
        
        let nextButton = app.buttons["nextButton"]
        XCTAssertTrue(nextButton.exists, "The next button should be shown before an email is sent.")
        XCTAssertTrue(nextButton.isEnabled, "The next button should be enabled once an address has been input.")
        
        XCTAssertFalse(app.staticTexts["waitingTitleLabel"].exists, "The waiting title should be hidden until an email is sent.")
        XCTAssertFalse(app.staticTexts["waitingMessageLabel"].exists, "The waiting message should be hidden until an email is sent.")

        let cancelButton = app.navigationBars.firstMatch.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should be shown.")
        XCTAssertEqual(cancelButton.label, "Cancel")
    }
    
    func testWaitingForEmailLink() {
        app.goToScreenWithIdentifier(MockAuthenticationVerifyEmailScreenState.hasSentEmail.title)
        
        XCTAssertFalse(app.staticTexts["titleLabel"].exists, "The title should be hidden once an email has been sent.")
        XCTAssertFalse(app.staticTexts["messageLabel"].exists, "The message should be hidden once an email has been sent.")
        XCTAssertFalse(app.textFields["addressTextField"].exists, "The text field should be hidden once an email has been sent.")
        XCTAssertFalse(app.buttons["nextButton"].exists, "The next button should be hidden once an email has been sent.")
        
        XCTAssertTrue(app.staticTexts["waitingTitleLabel"].exists, "The waiting title should be shown once an email has been sent.")
        XCTAssertTrue(app.staticTexts["waitingMessageLabel"].exists, "The waiting title should be shown once an email has been sent.")

        let backButton = app.navigationBars.firstMatch.buttons["cancelButton"]
        XCTAssertTrue(backButton.exists, "Back button should be shown.")
        XCTAssertEqual(backButton.label, "Back")
    }
}
