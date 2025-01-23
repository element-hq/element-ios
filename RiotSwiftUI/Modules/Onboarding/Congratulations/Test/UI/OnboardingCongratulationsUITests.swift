//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class OnboardingCongratulationsUITests: MockScreenTestCase {
    func testButtons() {
        app.goToScreenWithIdentifier(MockOnboardingCongratulationsScreenState.regular.title)
        
        let personalizeButton = app.buttons["personalizeButton"]
        XCTAssertTrue(personalizeButton.exists, "The personalization button should be shown.")
        
        let homeButton = app.buttons["homeButton"]
        XCTAssertTrue(homeButton.exists, "The home button should always be shown.")
    }
    
    func testButtonsWhenPersonalizationIsDisabled() {
        app.goToScreenWithIdentifier(MockOnboardingCongratulationsScreenState.personalizationDisabled.title)
        
        let personalizeButton = app.buttons["personalizeButton"]
        XCTAssertFalse(personalizeButton.exists, "The personalization button should be hidden.")
        
        let homeButton = app.buttons["homeButton"]
        XCTAssertTrue(homeButton.exists, "The home button should always be shown.")
    }
}
