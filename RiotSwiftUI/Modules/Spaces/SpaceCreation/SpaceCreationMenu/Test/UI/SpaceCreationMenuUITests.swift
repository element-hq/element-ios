// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class SpaceCreationMenuUITests: MockScreenTestCase {
    func testSpaceCreationMenuOptions() {
        app.goToScreenWithIdentifier(MockSpaceCreationMenuScreenState.options.title)
        
        let optionButtonCount = app.buttons.matching(identifier: "optionButton").count
        XCTAssertEqual(optionButtonCount, 2)
        
        let titleText = app.staticTexts["titleText"]
        XCTAssert(titleText.exists)
        XCTAssert(titleText.label == "Some title")

        let detailText = app.staticTexts["detailText"]
        XCTAssert(detailText.exists)
        XCTAssertEqual(detailText.label, "Some detail text")
    }
}
