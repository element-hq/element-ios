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

class OnboardingAvatarUITests: MockScreenTestCase {
    let userId = "@example:matrix.org"
    let displayName = "Jane"
    
    func testPlaceholderAvatar() {
        app.goToScreenWithIdentifier(MockOnboardingAvatarScreenState.placeholderAvatar(userId: userId, displayName: displayName).title)
        
        guard let firstLetter = displayName.uppercased().first else {
            XCTFail("Unable to get the first letter of the display name.")
            return
        }
        
        let placeholderAvatar = app.staticTexts["placeholderAvatar"]
        XCTAssertTrue(placeholderAvatar.exists, "The placeholder avatar should be shown.")
        XCTAssertEqual(placeholderAvatar.label, String(firstLetter), "The placeholder avatar should show the first letter of the display name.")
        
        let avatarImage = app.images["avatarImage"]
        XCTAssertFalse(avatarImage.exists, "The avatar image should be hidden as no selection has been made.")
        
        let saveButton = app.buttons["saveButton"]
        XCTAssertTrue(saveButton.exists, "There should be a save button.")
        XCTAssertFalse(saveButton.isEnabled, "The save button should not be enabled.")
    }
    
    func testUserSelectedAvatar() {
        app.goToScreenWithIdentifier(MockOnboardingAvatarScreenState.userSelectedAvatar(userId: userId, displayName: displayName).title)
        
        let placeholderAvatar = app.otherElements["placeholderAvatar"]
        XCTAssertFalse(placeholderAvatar.exists, "The placeholder avatar should be hidden.")
        
        let avatarImage = app.images["avatarImage"]
        XCTAssertTrue(avatarImage.exists, "The selected avatar should be shown.")
        
        let saveButton = app.buttons["saveButton"]
        XCTAssertTrue(saveButton.exists, "There should be a save button.")
        XCTAssertTrue(saveButton.isEnabled, "The save button should be enabled.")
    }
}
