// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class SpaceCreationSettingsUITests: MockScreenTestCase {
    func testPrivateSpace() {
        app.goToScreenWithIdentifier(MockSpaceCreationSettingsScreenState.privateSpace.title)
        
        let addressTextField = app.groups["addressTextField"]
        XCTAssertEqual(addressTextField.exists, false)
    }
    
    func testPublicValidated() {
        app.goToScreenWithIdentifier(MockSpaceCreationSettingsScreenState.validated.title)
        
        let addressTextField = app.groups["addressTextField"]
        XCTAssertEqual(addressTextField.exists, false)
    }
}
