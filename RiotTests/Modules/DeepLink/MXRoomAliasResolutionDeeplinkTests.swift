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
