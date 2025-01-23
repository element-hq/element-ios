//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
