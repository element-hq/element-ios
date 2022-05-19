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

class AuthenticationServerSelectionUITests: MockScreenTest {

    override class var screenType: MockScreenState.Type {
        return MockAuthenticationServerSelectionScreenState.self
    }

    override class func createTest() -> MockScreenTest {
        return AuthenticationServerSelectionUITests(selector: #selector(verifyAuthenticationServerSelectionScreen))
    }

    func verifyAuthenticationServerSelectionScreen() throws {
        guard let screenState = screenState as? MockAuthenticationServerSelectionScreenState else { fatalError("no screen") }
        switch screenState {
        case .matrix:
            verifyNormalState()
        case .emptyAddress:
            verifyEmptyAddress()
        case .invalidAddress:
            verifyInvalidAddress()
        case .nonModal:
            verifyNonModalPresentation()
        }
    }
    
    func verifyNormalState() {
        let serverTextField = app.textFields.element
        XCTAssertEqual(serverTextField.value as? String, "matrix.org", "The server shown should be matrix.org with the https scheme hidden.")
        
        let confirmButton = app.buttons["confirmButton"]
        XCTAssertEqual(confirmButton.label, VectorL10n.confirm, "The confirm button should say Confirm when in modal presentation.")
        XCTAssertTrue(confirmButton.exists, "The confirm button should always be shown.")
        XCTAssertTrue(confirmButton.isEnabled, "The confirm button should be enabled when there is an address.")
        
        let textFieldFooter = app.staticTexts["textFieldFooter"]
        XCTAssertTrue(textFieldFooter.exists)
        XCTAssertEqual(textFieldFooter.label, VectorL10n.authenticationServerSelectionServerFooter)
        
        let dismissButton = app.buttons["dismissButton"]
        XCTAssertTrue(dismissButton.exists, "The dismiss button should be shown during modal presentation.")
    }
    
    func verifyEmptyAddress() {
        let serverTextField = app.textFields.element
        XCTAssertEqual(serverTextField.value as? String, VectorL10n.authenticationServerSelectionServerUrl, "The text field should show placeholder text in this state.")
        
        let confirmButton = app.buttons["confirmButton"]
        XCTAssertTrue(confirmButton.exists, "The confirm button should always be shown.")
        XCTAssertFalse(confirmButton.isEnabled, "The confirm button should be disabled when the address is empty.")
    }
    
    func verifyInvalidAddress() {
        let serverTextField = app.textFields.element
        XCTAssertEqual(serverTextField.value as? String, "thisisbad", "The text field should show the entered server.")
        
        let confirmButton = app.buttons["confirmButton"]
        XCTAssertTrue(confirmButton.exists, "The confirm button should always be shown.")
        XCTAssertFalse(confirmButton.isEnabled, "The confirm button should be disabled when there is an error.")
        
        let textFieldFooter = app.staticTexts["textFieldFooter"]
        XCTAssertTrue(textFieldFooter.exists)
        XCTAssertEqual(textFieldFooter.label, VectorL10n.errorCommonMessage)
    }
    
    func verifyNonModalPresentation() {
        let dismissButton = app.buttons["dismissButton"]
        XCTAssertFalse(dismissButton.exists, "The dismiss button should be hidden when not in modal presentation.")
        
        let confirmButton = app.buttons["confirmButton"]
        XCTAssertEqual(confirmButton.label, VectorL10n.next, "The confirm button should say Next when not in modal presentation.")
    }
}
