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
        let bubbleCount = app.images.matching(identifier:"bubbleImage").count
        XCTAssertEqual(bubbleCount, 3)
        
        // and 4 text items
        let bubbleTextItemCount = app.staticTexts.matching(identifier:"bubbleTextContent").count
        XCTAssertEqual(bubbleTextItemCount, 4)
    }

}
