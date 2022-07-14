// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
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

class SpaceCreationMenuUITests: MockScreenTestCase {
    func testSpaceCreationMenuOptions() {
        app.goToScreenWithIdentifier(MockSpaceCreationMenuScreenState.options.title)
        
        let optionButtonCount = app.buttons.matching(identifier:"optionButton").count
        XCTAssertEqual(optionButtonCount, 2)
        
        let titleText = app.staticTexts["titleText"]
        XCTAssert(titleText.exists)
        XCTAssert(titleText.label == "Some title")

        let detailText = app.staticTexts["detailText"]
        XCTAssert(detailText.exists)
        XCTAssertEqual(detailText.label, "Some detail text")
    }
}
