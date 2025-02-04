//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class OnboardingDisplayNameUITests: MockScreenTestCase {
    func testEmptyTextField() {
        app.goToScreenWithIdentifier(MockOnboardingDisplayNameScreenState.emptyTextField.title)
        
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

    func testDisplayName() {
        let displayName = "Test User"
        app.goToScreenWithIdentifier(MockOnboardingDisplayNameScreenState.filledTextField(displayName: displayName).title)
        
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
    
    func testLongDisplayName() {
        let displayName = """
        Bacon ipsum dolor amet filet mignon chicken kevin andouille. Doner shoulder beef, brisket bresaola turkey jowl venison. Ham hock cow turducken, chislic venison doner short loin strip steak tri-tip jowl. Sirloin pork belly hamburger ribeye. Tail capicola alcatra short ribs turkey doner.
        """
        app.goToScreenWithIdentifier(MockOnboardingDisplayNameScreenState.longDisplayName(displayName: displayName).title)
        
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
