// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationRooms SpaceCreationRooms
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class SpaceCreationRoomsUITests: MockScreenTestCase {
    func testDefaultValues() {
        app.goToScreenWithIdentifier(MockSpaceCreationRoomsScreenState.defaultValues.title)
        
        let emailTextFieldsCount = app.textFields.matching(identifier: "roomTextField").count
        XCTAssertEqual(emailTextFieldsCount, 3)
    }
    
    func testValuesEntered() {
        app.goToScreenWithIdentifier(MockSpaceCreationRoomsScreenState.valuesEntered.title)
        
        let emailTextFieldsCount = app.textFields.matching(identifier: "roomTextField").count
        XCTAssertEqual(emailTextFieldsCount, 3)
    }
}
