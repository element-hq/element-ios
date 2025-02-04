//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class AuthenticationTermsUITests: MockScreenTestCase {
    func testMatrixDotOrg() {
        app.goToScreenWithIdentifier(MockAuthenticationTermsScreenState.matrixDotOrg.title)
        verifyTerms(accepted: false)
    }
    
    func testAccepted() {
        app.goToScreenWithIdentifier(MockAuthenticationTermsScreenState.accepted.title)
        verifyTerms(accepted: true)
    }
    
    func testMultiple() {
        app.goToScreenWithIdentifier(MockAuthenticationTermsScreenState.multiple.title)
        verifyTerms(accepted: false)
    }
    
    func verifyTerms(accepted: Bool) {
        let nextButton = app.buttons["nextButton"]
        XCTAssertTrue(nextButton.exists, "The next button should always exist.")
        XCTAssertEqual(nextButton.isEnabled, accepted, "The next button should be enabled when the terms are accepted")
    }
}
