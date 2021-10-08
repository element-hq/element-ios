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

@available(iOS 14.0, *)
class TemplateRoomChatUITests: MockScreenTest {
    
    override class var screenType: MockScreenState.Type {
        return MockTemplateRoomChatScreenState.self
    }

    override class func createTest() -> MockScreenTest {
        return TemplateRoomChatUITests(selector: #selector(verifyTemplateRoomChatScreen))
    }
    
    func verifyTemplateRoomChatScreen() throws {
        guard let screenState = screenState as? MockTemplateRoomChatScreenState else { fatalError("no screen") }
        switch screenState {
        case .initializingRoom:
            verifyInitializingRoom()
        case .failedToInitializeRoom:
            verifyFailedToInitializeRoom()
        case .noMessages:
            verifyNoMessages()
        case .messages:
            verifyMessages()
        }
    }
    
    func verifyInitializingRoom() {
        let loadingProgress = app.activityIndicators["loadingProgress"]
        XCTAssert(loadingProgress.exists)
    }
    
    func verifyFailedToInitializeRoom() {
        let errorMessage = app.staticTexts["errorMessage"]
        XCTAssert(errorMessage.exists)
    }
    
    func verifyNoMessages() {
        let errorMessage = app.staticTexts["errorMessage"]
        XCTAssert(errorMessage.exists)
    }
    
    func verifyMessages() {
        // Verify bubble grouping with:
        // 3 bubbles
        let bubbleCount = app.images.matching(identifier:"bubbleImage").count
        XCTAssertEqual(bubbleCount, 3)
        
        // and 4 text items
        let bubbleTextItemCount = app.staticTexts.matching(identifier:"bubbleTextContent").count
        XCTAssertEqual(bubbleTextItemCount, 4)
        
        
    }

}
