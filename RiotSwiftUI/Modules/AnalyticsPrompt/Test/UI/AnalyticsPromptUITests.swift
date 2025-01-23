//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class AnalyticsPromptUITests: MockScreenTestCase {
    /// Verify that the prompt is displayed correctly for new users.
    func testAnalyticsPromptNewUser() {
        app.goToScreenWithIdentifier(MockAnalyticsPromptScreenState.promptType(.newUser).title)
        
        let enableButton = app.buttons["enableButton"]
        let disableButton = app.buttons["disableButton"]
        
        XCTAssert(enableButton.exists)
        XCTAssert(disableButton.exists)
        
        XCTAssertEqual(enableButton.label, VectorL10n.enable)
        XCTAssertEqual(disableButton.label, VectorL10n.locationSharingInvalidAuthorizationNotNow)
    }
    
    /// Verify that the prompt is displayed correctly for when upgrading from Matomo.
    func testAnalyticsPromptUpgrade() {
        app.goToScreenWithIdentifier(MockAnalyticsPromptScreenState.promptType(.upgrade).title)
        
        let enableButton = app.buttons["enableButton"]
        let disableButton = app.buttons["disableButton"]
        
        XCTAssert(enableButton.exists)
        XCTAssert(disableButton.exists)
        
        XCTAssertEqual(enableButton.label, VectorL10n.analyticsPromptYes)
        XCTAssertEqual(disableButton.label, VectorL10n.analyticsPromptStop)
    }
}
