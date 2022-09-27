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

import RiotSwiftUI
import XCTest

class TemplateRoomListUITests: MockScreenTestCase {
    func testTemplateRoomListNoRooms() {
        app.goToScreenWithIdentifier(MockTemplateRoomListScreenState.noRooms.title)
        
        let errorMessage = app.staticTexts["errorMessage"]
        XCTAssert(errorMessage.exists)
        XCTAssert(errorMessage.label == "No Rooms")
    }
    
    func testTemplateRoomListRooms() {
        app.goToScreenWithIdentifier(MockTemplateRoomListScreenState.rooms.title)
        
        let displayNameCount = app.buttons.matching(identifier: "roomNameText").count
        XCTAssertEqual(displayNameCount, 3)
    }
}
