//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class AuthenticationServerSelectionUITests: MockScreenTestCase {
    func testRegisterState() {
        app.goToScreenWithIdentifier(MockAuthenticationServerSelectionScreenState.matrix.title)
        
        let title = app.staticTexts["headerTitle"]
        XCTAssertEqual(title.label, VectorL10n.authenticationServerSelectionRegisterTitle)
        let message = app.staticTexts["headerMessage"]
        XCTAssertEqual(message.label, VectorL10n.authenticationServerSelectionRegisterMessage)
        
        let serverTextField = app.textFields.element
        XCTAssertEqual(serverTextField.value as? String, "matrix.org", "The server shown should be matrix.org as passed to the view model init.")
        
        let confirmButton = app.buttons["confirmButton"]
        XCTAssertEqual(confirmButton.label, VectorL10n.confirm, "The confirm button should say Confirm when in modal presentation.")
        XCTAssertTrue(confirmButton.exists, "The confirm button should always be shown.")
        XCTAssertTrue(confirmButton.isEnabled, "The confirm button should be enabled when there is an address.")
        
        let textFieldFooter = app.staticTexts["textFieldFooter"]
        XCTAssertFalse(textFieldFooter.exists, "The footer shouldn't be shown when there isn't an error.")
        
        let dismissButton = app.buttons["dismissButton"]
        XCTAssertTrue(dismissButton.exists, "The dismiss button should be shown during modal presentation.")
    }
    
    func testLoginState() {
        app.goToScreenWithIdentifier(MockAuthenticationServerSelectionScreenState.login.title)
        
        let title = app.staticTexts["headerTitle"]
        XCTAssertEqual(title.label, VectorL10n.authenticationServerSelectionLoginTitle)
        let message = app.staticTexts["headerMessage"]
        XCTAssertEqual(message.label, VectorL10n.authenticationServerSelectionLoginMessage)
    }
    
    func testEmptyAddress() {
        app.goToScreenWithIdentifier(MockAuthenticationServerSelectionScreenState.emptyAddress.title)
        
        let serverTextField = app.textFields.element
        XCTAssertEqual(serverTextField.value as? String, VectorL10n.authenticationServerSelectionServerUrl, "The text field should show placeholder text in this state.")
        
        let confirmButton = app.buttons["confirmButton"]
        XCTAssertTrue(confirmButton.exists, "The confirm button should always be shown.")
        XCTAssertFalse(confirmButton.isEnabled, "The confirm button should be disabled when the address is empty.")
    }
    
    func testInvalidAddress() {
        app.goToScreenWithIdentifier(MockAuthenticationServerSelectionScreenState.invalidAddress.title)
        
        let serverTextField = app.textFields.element
        XCTAssertEqual(serverTextField.value as? String, "thisisbad", "The text field should show the entered server.")
        
        let confirmButton = app.buttons["confirmButton"]
        XCTAssertTrue(confirmButton.exists, "The confirm button should always be shown.")
        XCTAssertFalse(confirmButton.isEnabled, "The confirm button should be disabled when there is an error.")
        
        let textFieldFooter = app.staticTexts["textFieldFooter"]
        XCTAssertTrue(textFieldFooter.exists)
        XCTAssertEqual(textFieldFooter.label, VectorL10n.errorCommonMessage)
    }
    
    func testNonModalPresentation() {
        app.goToScreenWithIdentifier(MockAuthenticationServerSelectionScreenState.nonModal.title)
        
        let dismissButton = app.buttons["dismissButton"]
        XCTAssertFalse(dismissButton.exists, "The dismiss button should be hidden when not in modal presentation.")
        
        let confirmButton = app.buttons["confirmButton"]
        XCTAssertEqual(confirmButton.label, VectorL10n.next, "The confirm button should say Next when not in modal presentation.")
    }
}
