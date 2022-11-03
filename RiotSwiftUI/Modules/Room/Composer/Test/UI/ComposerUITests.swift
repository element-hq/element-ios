//
// Copyright 2022 New Vector Ltd
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
}
