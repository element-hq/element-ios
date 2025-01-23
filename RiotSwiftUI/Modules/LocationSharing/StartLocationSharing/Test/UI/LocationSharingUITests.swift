//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import RiotSwiftUI
import XCTest

class LocationSharingUITests: MockScreenTestCase {
    func testInitialUserLocation() {
        goToScreenWithIdentifier(MockLocationSharingScreenState.shareUserLocation.title)
        
        XCTAssertTrue(app.buttons["Cancel"].exists)
        XCTAssertTrue(app.otherElements["Map"].exists)
    }
    
    // Need a delay when showing the map otherwise the simulator breaks
    private func goToScreenWithIdentifier(_ identifier: String) {
        app.goToScreenWithIdentifier(identifier)
        sleep(2)
    }
}
