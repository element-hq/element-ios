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

class AuthenticationVerifyMsisdnUITests: MockScreenTestCase {
    func testEmptyPhoneNumber() {
        app.goToScreenWithIdentifier(MockAuthenticationVerifyMsisdnScreenState.emptyPhoneNumber.title)
        
        let titleLabel = app.staticTexts["titleLabel"]
        XCTAssertTrue(titleLabel.exists, "The title should be shown.")

        let messageLabel = app.staticTexts["messageLabel"]
        XCTAssertTrue(messageLabel.exists, "The message should be shown.")
        
        let phoneNumberTextField = app.textFields["phoneNumberTextField"]
        XCTAssertTrue(phoneNumberTextField.exists, "The text field should be shown before an SMS is sent.")
        XCTAssertEqual(phoneNumberTextField.value as? String, VectorL10n.authenticationVerifyMsisdnTextFieldPlaceholder,
                       "The text field should be showing the placeholder before text is input.")
        
        let nextButton = app.buttons["nextButton"]
        XCTAssertTrue(nextButton.exists, "The next button should be shown.")
        XCTAssertFalse(nextButton.isEnabled, "The next button should be disabled before text is input.")

        let resendButton = app.buttons["resendButton"]
        XCTAssertFalse(resendButton.exists, "Resend button should be hidden until an SMS is sent.")

        let cancelButton = app.navigationBars.firstMatch.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should be shown.")
        XCTAssertEqual(cancelButton.label, "Cancel")
    }
    
    func testEnteredPhoneNumber() {
        app.goToScreenWithIdentifier(MockAuthenticationVerifyMsisdnScreenState.enteredPhoneNumber.title)
        
        let titleLabel = app.staticTexts["titleLabel"]
        XCTAssertTrue(titleLabel.exists, "The title should be shown.")

        let messageLabel = app.staticTexts["messageLabel"]
        XCTAssertTrue(messageLabel.exists, "The message should be shown.")
        
        let phoneNumberTextField = app.textFields["phoneNumberTextField"]
        XCTAssertTrue(phoneNumberTextField.exists, "The text field should be shown before an SMS is sent.")
        XCTAssertEqual(phoneNumberTextField.value as? String, "+44 XXXXXXXXX", "The text field should show entered phone number.")
        
        let nextButton = app.buttons["nextButton"]
        XCTAssertTrue(nextButton.exists, "The next button should be shown.")
        XCTAssertTrue(nextButton.isEnabled, "The next button should be enabled once a phone number has been input.")

        let resendButton = app.buttons["resendButton"]
        XCTAssertFalse(resendButton.exists, "Resend button should be hidden until an SMS is sent.")

        let cancelButton = app.navigationBars.firstMatch.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should be shown.")
        XCTAssertEqual(cancelButton.label, "Cancel")
    }
    
    func testHasSentSMS() {
        app.goToScreenWithIdentifier(MockAuthenticationVerifyMsisdnScreenState.hasSentSMS.title)
        
        let titleLabel = app.staticTexts["titleLabel"]
        XCTAssertTrue(titleLabel.exists, "The title should be shown.")

        let messageLabel = app.staticTexts["messageLabel"]
        XCTAssertTrue(messageLabel.exists, "The message should be shown.")

        let phoneNumberTextField = app.textFields["phoneNumberTextField"]
        XCTAssertFalse(phoneNumberTextField.exists, "The phone number text field should be hidden once an SMS has been sent.")

        let otpTextField = app.textFields["otpTextField"]
        XCTAssertTrue(otpTextField.exists, "The OTP text field should be shown once an SMS has been sent.")
        XCTAssertEqual(otpTextField.value as? String, VectorL10n.authenticationVerifyMsisdnOtpTextFieldPlaceholder,
                       "The text field should be showing the placeholder before text is input.")

        let nextButton = app.buttons["nextButton"]
        XCTAssertTrue(nextButton.exists, "The next button should be shown.")
        XCTAssertFalse(nextButton.isEnabled, "The next button should be disabled before text is input.")

        let resendButton = app.buttons["resendButton"]
        XCTAssertTrue(resendButton.exists, "Resend button should be shown after SMS sent.")
        XCTAssertTrue(resendButton.isEnabled, "Resend button should be enabled after an SMS sent once.")

        let backButton = app.navigationBars.firstMatch.buttons["cancelButton"]
        XCTAssertTrue(backButton.exists, "Back button should be shown.")
        XCTAssertEqual(backButton.label, "Back")
    }

    func testEnteredOTP() {
        app.goToScreenWithIdentifier(MockAuthenticationVerifyMsisdnScreenState.enteredOTP.title)
        
        let titleLabel = app.staticTexts["titleLabel"]
        XCTAssertTrue(titleLabel.exists, "The title should be shown.")

        let messageLabel = app.staticTexts["messageLabel"]
        XCTAssertTrue(messageLabel.exists, "The message should be shown.")

        let phoneNumberTextField = app.textFields["phoneNumberTextField"]
        XCTAssertFalse(phoneNumberTextField.exists, "The phone number text field should be hidden once an SMS has been sent.")

        let otpTextField = app.textFields["otpTextField"]
        XCTAssertTrue(otpTextField.exists, "The OTP text field should be shown once an SMS has been sent.")
        XCTAssertEqual(otpTextField.value as? String, "123456", "The text field should show entered OTP.")
        
        let nextButton = app.buttons["nextButton"]
        XCTAssertTrue(nextButton.exists, "The next button should be shown.")
        XCTAssertTrue(nextButton.isEnabled, "The next button should be enabled once an OTP has been input.")

        let resendButton = app.buttons["resendButton"]
        XCTAssertTrue(resendButton.exists, "Resend button should be shown after SMS sent.")
        XCTAssertTrue(resendButton.isEnabled, "Resend button should be enabled after an SMS sent once.")

        let backButton = app.navigationBars.firstMatch.buttons["cancelButton"]
        XCTAssertTrue(backButton.exists, "Back button should be shown.")
        XCTAssertEqual(backButton.label, "Back")
    }

}
