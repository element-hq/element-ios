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
class TemplateRoomListUITests: MockScreenTest {
    
    override class var screenType: MockScreenState.Type {
        return MockTemplateRoomListScreenState.self
    }

    override class func createTest() -> MockScreenTest {
        return TemplateRoomListUITests(selector: #selector(verifyTemplateRoomListScreen))
    }
    
    func verifyTemplateRoomListScreen() throws {
        guard let screenState = screenState as? MockTemplateRoomListScreenState else { fatalError("no screen") }
        switch screenState {
        case .presence(let presence):
            verifyTemplateRoomListPresence(presence: presence)
        case .longDisplayName(let name):
            verifyTemplateRoomListLongName(name: name)
        }
    }
    
    func verifyTemplateRoomListPresence(presence: TemplateRoomListPresence) {
        let presenceText = app.staticTexts["presenceText"]
        XCTAssert(presenceText.exists)
        XCTAssert(presenceText.label == presence.title)
    }
    
    func verifyTemplateRoomListLongName(name: String) {
        let displayNameText = app.staticTexts["displayNameText"]
        XCTAssert(displayNameText.exists)
        XCTAssert(displayNameText.label == name)
    }

}
