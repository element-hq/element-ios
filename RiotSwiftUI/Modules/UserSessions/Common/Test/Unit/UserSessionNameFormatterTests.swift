//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import RiotSwiftUI

class UserSessionNameFormatterTests: XCTestCase {
    func testSessionDisplayNameTrumpsDeviceTypeName() {
        XCTAssertEqual("Johnny's iPhone", UserSessionNameFormatter.sessionName(sessionId: "sessionId", sessionDisplayName: "Johnny's iPhone"))
    }
    
    func testEmptySessionDisplayNameFallsBackToDeviceTypeName() {
        XCTAssertEqual("sessionId", UserSessionNameFormatter.sessionName(sessionId: "sessionId", sessionDisplayName: ""))
    }

    func testNilSessionDisplayNameFallsBackToDeviceTypeName() {
        XCTAssertEqual("sessionId", UserSessionNameFormatter.sessionName(sessionId: "sessionId", sessionDisplayName: nil))
    }
}
