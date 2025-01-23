//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

final class ComposerLinkActionUITests: MockScreenTestCase {
    func testCreate() {
        app.goToScreenWithIdentifier(MockComposerLinkActionScreenState.create.title, shouldUseSlowTyping: true)
        XCTAssertFalse(app.buttons[VectorL10n.remove].exists)
        XCTAssertTrue(app.buttons[VectorL10n.cancel].exists)
        let saveButton = app.buttons[VectorL10n.save]
        XCTAssertTrue(saveButton.exists)
        XCTAssertFalse(saveButton.isEnabled)
        XCTAssertFalse(app.textFields["textTextField"].exists)
        let linkTextField = app.textFields["linkTextField"]
        XCTAssertTrue(linkTextField.exists)
        linkTextField.tap()
        linkTextField.clearAndTypeText("element.io")
        XCTAssertTrue(saveButton.isEnabled)
    }
    
    func testCreateWithText() {
        app.goToScreenWithIdentifier(MockComposerLinkActionScreenState.createWithText.title, shouldUseSlowTyping: true)
        XCTAssertFalse(app.buttons[VectorL10n.remove].exists)
        XCTAssertTrue(app.buttons[VectorL10n.cancel].exists)
        let saveButton = app.buttons[VectorL10n.save]
        XCTAssertTrue(saveButton.exists)
        XCTAssertFalse(saveButton.isEnabled)
        let textTextField = app.textFields["textTextField"]
        XCTAssertTrue(textTextField.exists)
        let linkTextField = app.textFields["linkTextField"]
        XCTAssertTrue(linkTextField.exists)
        linkTextField.tap()
        linkTextField.typeText("element.io")
        XCTAssertFalse(saveButton.isEnabled)
        textTextField.tap()
        textTextField.typeText("test")
        XCTAssertTrue(saveButton.isEnabled)
    }
    
    func testEdit() {
        app.goToScreenWithIdentifier(MockComposerLinkActionScreenState.edit.title, shouldUseSlowTyping: true)
        XCTAssertTrue(app.buttons[VectorL10n.remove].exists)
        XCTAssertTrue(app.buttons[VectorL10n.cancel].exists)
        let saveButton = app.buttons[VectorL10n.save]
        XCTAssertTrue(saveButton.exists)
        XCTAssertFalse(saveButton.isEnabled)
        XCTAssertFalse(app.textFields["textTextField"].exists)
        let linkTextField = app.textFields["linkTextField"]
        XCTAssertTrue(linkTextField.exists)
        let value = linkTextField.value as? String
        XCTAssertEqual(value, "https://element.io")
        linkTextField.clearAndTypeText("")
        XCTAssertFalse(saveButton.isEnabled)
        linkTextField.clearAndTypeText("matrix.org")
        XCTAssertTrue(saveButton.isEnabled)
    }
}
