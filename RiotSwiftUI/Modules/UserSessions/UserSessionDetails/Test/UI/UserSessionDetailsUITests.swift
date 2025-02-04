//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class UserSessionDetailsUITests: MockScreenTestCase {
    func test_screenWithAllTheContent() throws {
        app.goToScreenWithIdentifier(MockUserSessionDetailsScreenState.allSections.title)

        let rows = app.staticTexts.matching(identifier: "UserSessionDetailsItem.title")
        XCTAssertEqual(rows.count, 6)
    }
    
    func test_screenWithSessionSectionOnly() throws {
        app.goToScreenWithIdentifier(MockUserSessionDetailsScreenState.sessionSectionOnly.title)

        let rows = app.staticTexts.matching(identifier: "UserSessionDetailsItem.title")
        XCTAssertEqual(rows.count, 3)
    }
}
