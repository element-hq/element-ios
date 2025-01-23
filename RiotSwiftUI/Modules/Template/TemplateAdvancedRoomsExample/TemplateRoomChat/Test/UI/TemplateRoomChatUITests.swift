//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class TemplateRoomChatUITests: MockScreenTestCase {
    func testInitializingRoom() {
        app.goToScreenWithIdentifier(MockTemplateRoomChatScreenState.initializingRoom.title)
        
        let loadingProgress = app.activityIndicators["loadingProgress"]
        XCTAssert(loadingProgress.exists)
    }
    
    func testFailedToInitializeRoom() {
        app.goToScreenWithIdentifier(MockTemplateRoomChatScreenState.failedToInitializeRoom.title)
        
        let errorMessage = app.staticTexts["errorMessage"]
        XCTAssert(errorMessage.exists)
    }
    
    func testNoMessages() {
        app.goToScreenWithIdentifier(MockTemplateRoomChatScreenState.noMessages.title)
        
        let errorMessage = app.staticTexts["errorMessage"]
        XCTAssert(errorMessage.exists)
    }
    
    func testMessages() {
        app.goToScreenWithIdentifier(MockTemplateRoomChatScreenState.messages.title)
        
        // Verify bubble grouping with:
        // 3 bubbles
        let bubbleCount = app.images.matching(identifier: "bubbleImage").count
        XCTAssertEqual(bubbleCount, 3)
        
        // and 4 text items
        let bubbleTextItemCount = app.staticTexts.matching(identifier: "bubbleTextContent").count
        XCTAssertEqual(bubbleTextItemCount, 4)
    }
}
