//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class ComposerCreateActionListUITests: MockScreenTestCase {
    func testFullList() throws {
        app.goToScreenWithIdentifier(MockComposerCreateActionListScreenState.fullList.title)
        
        XCTAssert(app.staticTexts[ComposerCreateAction.photoLibrary.accessibilityIdentifier].exists)
        XCTAssert(app.staticTexts[ComposerCreateAction.location.accessibilityIdentifier].exists)
    }
    
    func testPartialList() throws {
        app.goToScreenWithIdentifier(MockComposerCreateActionListScreenState.partialList.title)
        
        XCTAssert(app.staticTexts[ComposerCreateAction.photoLibrary.accessibilityIdentifier].exists)
        XCTAssertFalse(app.staticTexts[ComposerCreateAction.location.accessibilityIdentifier].exists)
    }
}
