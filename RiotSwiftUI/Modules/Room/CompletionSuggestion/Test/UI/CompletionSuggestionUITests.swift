//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class CompletionSuggestionUITests: MockScreenTestCase {
    func testCompletionSuggestionScreen() throws {
        app.goToScreenWithIdentifier(MockCompletionSuggestionScreenState.multipleResults.title)
        
        let firstButton = app.buttons["displayNameText-userIdText"].firstMatch
        XCTAssert(firstButton.waitForExistence(timeout: 10))
    }
}
