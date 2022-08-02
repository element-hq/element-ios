// 
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
        
        XCTAssertEqual(resolution.deeplinkFragment, "!abc%3Amatrix.org")
    }
    
    func test_fragmentContainsSingleServer() {
        let resolution = MXRoomAliasResolution()
        resolution.roomId = "xyz:element.io"
        resolution.servers = [
            "matrix.org"
        ]
        
        XCTAssertEqual(resolution.deeplinkFragment, "xyz%3Aelement.io%3Fvia%3Dmatrix.org")
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
        
        XCTAssertEqual(resolution.deeplinkFragment, "mno%3Aserver.com%3Fvia%3Dserver.com%26via%3Delement.io%26via%3Dwikipedia.org%26via%3Dmatrix.org")
    }
}
