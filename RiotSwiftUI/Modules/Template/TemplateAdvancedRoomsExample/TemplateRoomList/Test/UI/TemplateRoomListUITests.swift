//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
