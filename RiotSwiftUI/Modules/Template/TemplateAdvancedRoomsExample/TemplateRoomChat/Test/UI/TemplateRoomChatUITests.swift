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
        case .presence(let presence):
            verifyTemplateRoomChatPresence(presence: presence)
        case .longDisplayName(let name):
            verifyTemplateRoomChatLongName(name: name)
        }
    }
    
    func verifyTemplateRoomChatPresence(presence: TemplateRoomChatPresence) {
        let presenceText = app.staticTexts["presenceText"]
        XCTAssert(presenceText.exists)
        XCTAssert(presenceText.label == presence.title)
    }
    
    func verifyTemplateRoomChatLongName(name: String) {
        let displayNameText = app.staticTexts["displayNameText"]
        XCTAssert(displayNameText.exists)
        XCTAssert(displayNameText.label == name)
    }

}
