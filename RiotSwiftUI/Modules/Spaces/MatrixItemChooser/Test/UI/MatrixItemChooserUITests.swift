//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class MatrixItemChooserUITests: MockScreenTestCase {
    func testEmptyScreen() {
        app.goToScreenWithIdentifier(MockMatrixItemChooserScreenState.noItems.title)
        
        XCTAssertEqual(app.staticTexts["titleText"].label, VectorL10n.spacesCreationAddRoomsTitle)
        XCTAssertEqual(app.staticTexts["messageText"].label, VectorL10n.spacesCreationAddRoomsMessage)
        XCTAssertEqual(app.staticTexts["emptyListMessage"].exists, true)
        XCTAssertEqual(app.staticTexts["emptyListMessage"].label, VectorL10n.spacesNoResultFoundTitle)
    }

    func testPopulatedScreen() {
        app.goToScreenWithIdentifier(MockMatrixItemChooserScreenState.items.title)
        
        XCTAssertEqual(app.staticTexts["titleText"].label, VectorL10n.spacesCreationAddRoomsTitle)
        XCTAssertEqual(app.staticTexts["messageText"].label, VectorL10n.spacesCreationAddRoomsMessage)
        XCTAssertEqual(app.staticTexts["emptyListMessage"].exists, false)
    }

    func testPopulatedWithSelectionScreen() {
        app.goToScreenWithIdentifier(MockMatrixItemChooserScreenState.selectedItems.title)
        
        XCTAssertEqual(app.staticTexts["titleText"].label, VectorL10n.spacesCreationAddRoomsTitle)
        XCTAssertEqual(app.staticTexts["messageText"].label, VectorL10n.spacesCreationAddRoomsMessage)
        XCTAssertEqual(app.staticTexts["emptyListMessage"].exists, false)
    }
}
