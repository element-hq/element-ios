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

class OnboardingDisplayNameUITests: MockScreenTest {

    override class var screenType: MockScreenState.Type {
        return MockOnboardingDisplayNameScreenState.self
    }

    override class func createTest() -> MockScreenTest {
        return OnboardingDisplayNameUITests(selector: #selector(verifyOnboardingDisplayNameScreen))
    }

    func verifyOnboardingDisplayNameScreen() throws {
        guard let screenState = screenState as? MockOnboardingDisplayNameScreenState else { fatalError("no screen") }
        switch screenState {
        case .emptyTextField:
            verifyEmptyTextField()
        case .filledTextField(let displayName):
            verifyDisplayName(displayName: displayName)
        case .longDisplayName(displayName: let displayName):
            verifyLongDisplayName(displayName: displayName)
        }
    }

    func verifyEmptyTextField() {
        let textField = app.textFields.element
        XCTAssertTrue(textField.exists, "The textfield should always be shown.")
        XCTAssertEqual(textField.value as? String, VectorL10n.onboardingDisplayNamePlaceholder, "When the textfield is empty, the value should match the placeholder.")
        XCTAssertEqual(textField.placeholderValue, VectorL10n.onboardingDisplayNamePlaceholder, "The textfield's placeholder should be set.")
        
        let footer = app.staticTexts["textFieldFooter"]
        XCTAssertTrue(footer.exists, "The textfield's footer should always be shown.")
        XCTAssertEqual(footer.label, VectorL10n.onboardingDisplayNameHint, "The footer should display a hint when no text is set.")
        
        let saveButton = app.buttons["saveButton"]
        XCTAssertTrue(saveButton.exists, "There should be a save button.")
        XCTAssertFalse(saveButton.isEnabled, "The save button should not be enabled.")
    }

    func verifyDisplayName(displayName: String) {
        let textField = app.textFields.element
        XCTAssertTrue(textField.exists, "The textfield should always be shown.")
        XCTAssertEqual(textField.value as? String, displayName, "When a name has been set, it should show in the textfield.")
        XCTAssertEqual(textField.placeholderValue, VectorL10n.onboardingDisplayNamePlaceholder, "The textfield's placeholder should be set.")
        
        let saveButton = app.buttons["saveButton"]
        XCTAssertTrue(saveButton.exists, "There should be a save button.")
        XCTAssertTrue(saveButton.isEnabled, "The save button should be enabled.")
        
        let footer = app.staticTexts["textFieldFooter"]
        XCTAssertTrue(footer.exists, "The textfield's footer should always be shown.")
        XCTAssertEqual(footer.label, VectorL10n.onboardingDisplayNameHint, "The footer should display a hint when an acceptable name is entered.")
    }
    
    func verifyLongDisplayName(displayName: String) {
        let textField = app.textFields.element
        XCTAssertTrue(textField.exists, "The textfield should always be shown.")
        XCTAssertEqual(textField.value as? String, displayName, "When a name has been set, it should show in the textfield.")
        XCTAssertEqual(textField.placeholderValue, VectorL10n.onboardingDisplayNamePlaceholder, "The textfield's placeholder should be set.")
        
        let footer = app.staticTexts["textFieldFooter"]
        XCTAssertTrue(footer.exists, "The textfield's footer should always be shown.")
        XCTAssertEqual(footer.label, VectorL10n.onboardingDisplayNameMaxLength, "The footer should display an error when the display name is too long.")
        
        let saveButton = app.buttons["saveButton"]
        XCTAssertTrue(saveButton.exists, "There should be a save button.")
        XCTAssertFalse(saveButton.isEnabled, "The save button should not be enabled.")
    }
}
