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
