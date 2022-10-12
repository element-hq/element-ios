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
        
        XCTAssertTrue(!app.otherElements["contextView"].exists)
        let wysiwygTextView = app.textViews.allElementsBoundByIndex[0]
        XCTAssertTrue(wysiwygTextView.exists)
        let sendButton = app.buttons["sendButton"]
        XCTAssertTrue(!sendButton.exists)
        wysiwygTextView.tap()
        wysiwygTextView.typeText("test")
        XCTAssertTrue(sendButton.exists)
        XCTAssertTrue(!app.buttons["editButton"].exists)
    }
    
    func testEditMode() throws {
        app.goToScreenWithIdentifier(MockComposerScreenState.edit.title)

        let contextView = app.otherElements["contextView"]
        XCTAssertTrue(contextView.exists)
        let cancelButton = app.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.exists)
        let wysiwygTextView = app.textViews.allElementsBoundByIndex[0]
        XCTAssertTrue(wysiwygTextView.exists)
        let editButton = app.buttons["editButton"]
        XCTAssert(!editButton.exists)
        wysiwygTextView.tap()
        wysiwygTextView.typeText("test")
        XCTAssertTrue(editButton.exists)
        XCTAssertTrue(!app.buttons["sendButton"].exists)
        
        cancelButton.tap()
        XCTAssertTrue(!contextView.exists)
        let textViewContent = wysiwygTextView.value as! String
        XCTAssertTrue(textViewContent.isEmpty)
    }
    
    func testReplyMode() throws {
        app.goToScreenWithIdentifier(MockComposerScreenState.reply.title)
        
        let contextView = app.otherElements["contextView"]
        XCTAssertTrue(contextView.exists)
        let cancelButton = app.buttons["cancelButton"]
        XCTAssertTrue(cancelButton.exists)
        let wysiwygTextView = app.textViews.allElementsBoundByIndex[0]
        XCTAssertTrue(wysiwygTextView.exists)
        let sendButton = app.buttons["sendButton"]
        XCTAssertTrue(!sendButton.exists)
        wysiwygTextView.tap()
        wysiwygTextView.typeText("test")
        XCTAssertTrue(sendButton.exists)
        cancelButton.tap()
        XCTAssertTrue(!contextView.exists)
        let textViewContent = wysiwygTextView.value as! String
        XCTAssertTrue(!textViewContent.isEmpty)
    }
}
