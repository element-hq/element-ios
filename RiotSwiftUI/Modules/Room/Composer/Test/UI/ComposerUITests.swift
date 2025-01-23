//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

final class ComposerUITests: MockScreenTestCase {
    func testSendMode() throws {
        app.goToScreenWithIdentifier(MockComposerScreenState.send.title)
        
        XCTAssertFalse(app.buttons["cancelButton"].exists)
        let wysiwygTextView = app.textViews.allElementsBoundByIndex[0]
        XCTAssertTrue(wysiwygTextView.exists)
        let sendButton = app.buttons["sendButton"]
        XCTAssertFalse(sendButton.exists)
        wysiwygTextView.tap()
        wysiwygTextView.typeText("test")
        XCTAssertTrue(sendButton.exists)
        XCTAssertFalse(app.buttons["editButton"].exists)
        
        let maximiseButton = app.buttons["maximiseButton"]
        let minimiseButton = app.buttons["minimiseButton"]
        XCTAssertFalse(minimiseButton.exists)
        XCTAssertTrue(maximiseButton.exists)
        
        maximiseButton.tap()
        XCTAssertTrue(minimiseButton.exists)
        XCTAssertFalse(maximiseButton.exists)
        
        minimiseButton.tap()
        XCTAssertFalse(minimiseButton.exists)
        XCTAssertTrue(maximiseButton.exists)
    }
    
    // This test requires "connect hardware keyboard" to be off on the simulator
    // And may not work on the CI
    func testFastTyping() throws {
        app.goToScreenWithIdentifier(MockComposerScreenState.send.title)
        let text = "fast typing test"
        let wysiwygTextView = app.textViews.allElementsBoundByIndex[0]
        XCTAssertTrue(wysiwygTextView.exists)
        wysiwygTextView.tap()
        sleep(1)
        wysiwygTextView.typeText(text)
        let options = XCTExpectedFailure.Options()
        options.isStrict = false
        XCTExpectFailure("Test may fail on CI", options: options)
        let value = wysiwygTextView.value as? String
        XCTAssert(value == text, "Text view value is: \(value ?? "nil")")
    }
    
    // This test requires "connect hardware keyboard" to be off on the simulator
    // And may not work on the CI
    func testLongPressDelete() throws {
        app.goToScreenWithIdentifier(MockComposerScreenState.send.title)
        let text = "test1 test2 test3 test4 test5 test6 test7"
        let wysiwygTextView = app.textViews.allElementsBoundByIndex[0]
        XCTAssertTrue(wysiwygTextView.exists)
        wysiwygTextView.tap()
        sleep(1)
        wysiwygTextView.typeText(text)
        sleep(1)
        app.keys["delete"].press(forDuration: 10.0)
        let options = XCTExpectedFailure.Options()
        options.isStrict = false
        XCTExpectFailure("Test may fail on CI", options: options)
        let value = wysiwygTextView.value as? String
        XCTAssert(value == "", "Text view value is: \(value ?? "nil")")
    }
    
    func testReplyMode() throws {
        app.goToScreenWithIdentifier(MockComposerScreenState.reply.title)
        
        let wysiwygTextView = app.textViews.allElementsBoundByIndex[0]
        XCTAssertTrue(wysiwygTextView.exists)
        let sendButton = app.buttons["sendButton"]
        XCTAssertFalse(sendButton.exists)
        
        let cancelButton = app.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.exists)
        
        let contextDescription = app.staticTexts["contextDescription"]
        XCTAssertTrue(contextDescription.exists)
        XCTAssert(contextDescription.label == VectorL10n.roomMessageReplyingTo("TestUser"))
        
        wysiwygTextView.tap()
        wysiwygTextView.typeText("test")
        XCTAssertTrue(sendButton.exists)
        XCTAssertFalse(app.buttons["editButton"].exists)
        
        cancelButton.tap()
        let textViewContent = wysiwygTextView.value as! String
        XCTAssertFalse(textViewContent.isEmpty)
        XCTAssertFalse(cancelButton.exists)
        
        let maximiseButton = app.buttons["maximiseButton"]
        let minimiseButton = app.buttons["minimiseButton"]
        XCTAssertFalse(minimiseButton.exists)
        XCTAssertTrue(maximiseButton.exists)
        
        maximiseButton.tap()
        XCTAssertTrue(minimiseButton.exists)
        XCTAssertFalse(maximiseButton.exists)
        
        minimiseButton.tap()
        XCTAssertFalse(minimiseButton.exists)
        XCTAssertTrue(maximiseButton.exists)
    }
    
    func testEditMode() throws {
        app.goToScreenWithIdentifier(MockComposerScreenState.edit.title)

        let wysiwygTextView = app.textViews.allElementsBoundByIndex[0]
        XCTAssertTrue(wysiwygTextView.exists)
        let editButton = app.buttons["editButton"]
        XCTAssertFalse(editButton.exists)
        
        let cancelButton = app.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.exists)
        
        let contextDescription = app.staticTexts["contextDescription"]
        XCTAssertTrue(contextDescription.exists)
        XCTAssert(contextDescription.label == VectorL10n.roomMessageEditing)
        
        wysiwygTextView.tap()
        wysiwygTextView.typeText("test")
        XCTAssertTrue(editButton.exists)
        XCTAssertFalse(app.buttons["sendButton"].exists)
        
        cancelButton.tap()
        let textViewContent = wysiwygTextView.value as! String
        XCTAssertTrue(textViewContent.isEmpty)
        XCTAssertFalse(cancelButton.exists)
        
        let maximiseButton = app.buttons["maximiseButton"]
        let minimiseButton = app.buttons["minimiseButton"]
        XCTAssertFalse(minimiseButton.exists)
        XCTAssertTrue(maximiseButton.exists)
        
        maximiseButton.tap()
        XCTAssertTrue(minimiseButton.exists)
        XCTAssertFalse(maximiseButton.exists)
        
        minimiseButton.tap()
        XCTAssertFalse(minimiseButton.exists)
        XCTAssertTrue(maximiseButton.exists)
    }

    func testCreatingListDisplaysIndentButtons() throws {
        app.goToScreenWithIdentifier(MockComposerScreenState.send.title)

        XCTAssertFalse(composerToolbarButton(in: app, for: .indent).exists)
        XCTAssertFalse(composerToolbarButton(in: app, for: .indent).exists)
        // Create a list.
        composerToolbarButton(in: app, for: .orderedList).tap()
        XCTAssertTrue(composerToolbarButton(in: app, for: .indent).exists)
        XCTAssertTrue(composerToolbarButton(in: app, for: .indent).exists)
        // Remove the list
        composerToolbarButton(in: app, for: .orderedList).tap()
        XCTAssertFalse(composerToolbarButton(in: app, for: .indent).exists)
        XCTAssertFalse(composerToolbarButton(in: app, for: .indent).exists)
    }
}

private extension ComposerUITests {
    /// Returns the button of the composer toolbar associated with given format type.
    ///
    /// - Parameters:
    ///   - app: the running app
    ///   - formatType: format type to look for
    /// - Returns: XCUIElement for the button
    func composerToolbarButton(in app: XCUIApplication, for formatType: FormatType) -> XCUIElement {
        // Note: state is irrelevant here, we're just building this to retrieve the accessibility identifier.
        app.buttons[FormatItem(type: formatType, state: .enabled).accessibilityIdentifier]
    }
}
