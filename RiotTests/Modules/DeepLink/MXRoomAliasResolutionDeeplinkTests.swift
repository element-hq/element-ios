// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import XCTest
@testable import Element

class MXRoomAliasResolutionDeeplinkTests: XCTestCase {
    func test_fragmentIsNilForInvalidResolution() {
        let resolution = MXRoomAliasResolution()
        XCTAssertNil(resolution.deeplinkFragment)
    }
    
    func test_fragmentDoesNotContainServers_ifNoServers() {
        let resolution = MXRoomAliasResolution()
        resolution.roomId = "!abc:matrix.org"
        
        XCTAssertEqual(resolution.deeplinkFragment, "!abc:matrix.org")
    }
    
    func test_fragmentContainsSingleServer() {
        let resolution = MXRoomAliasResolution()
        resolution.roomId = "xyz:element.io"
        resolution.servers = [
            "matrix.org"
        ]
        
        XCTAssertEqual(resolution.deeplinkFragment, "xyz:element.io?via=matrix.org")
    }
    
    func test_fragmentContainsMultipleSerivers() {
        let resolution = MXRoomAliasResolution()
        resolution.roomId = "mno:server.com"
        resolution.servers = [
            "server.com",
            "element.io",
            "wikipedia.org",
            "matrix.org"
        ]
        
        XCTAssertEqual(resolution.deeplinkFragment, "mno:server.com?via=server.com&via=element.io&via=wikipedia.org&via=matrix.org")
    }
}
