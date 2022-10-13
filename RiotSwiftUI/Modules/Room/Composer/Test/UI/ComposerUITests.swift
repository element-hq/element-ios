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
    }
    
    func testEditMode() throws {
        app.goToScreenWithIdentifier(MockComposerScreenState.edit.title)

        let cancelButton = app.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.exists)
        let wysiwygTextView = app.textViews.allElementsBoundByIndex[0]
        XCTAssertTrue(wysiwygTextView.exists)
        let editButton = app.buttons["editButton"]
        XCTAssert(!editButton.exists)
        
        wysiwygTextView.tap()
        wysiwygTextView.typeText("test")
        XCTAssertTrue(editButton.exists)
        XCTAssertFalse(app.buttons["sendButton"].exists)
        
        cancelButton.tap()
        XCTAssertFalse(cancelButton.exists)
        let textViewContent = wysiwygTextView.value as! String
        XCTAssertTrue(textViewContent.isEmpty)
    }
    
    func testReplyMode() throws {
        app.goToScreenWithIdentifier(MockComposerScreenState.reply.title)
        
        let cancelButton = app.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.exists)
        let wysiwygTextView = app.textViews.allElementsBoundByIndex[0]
        XCTAssertTrue(wysiwygTextView.exists)
        let sendButton = app.buttons["sendButton"]
        XCTAssertFalse(sendButton.exists)
        
        wysiwygTextView.tap()
        wysiwygTextView.typeText("test")
        XCTAssertTrue(sendButton.exists)
        XCTAssertFalse(app.buttons["editButton"].exists)
        
        cancelButton.tap()
        XCTAssertFalse(cancelButton.exists)
        let textViewContent = wysiwygTextView.value as! String
        XCTAssertFalse(textViewContent.isEmpty)
    }
}
