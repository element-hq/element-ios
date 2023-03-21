// 
// Copyright 2023 New Vector Ltd
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

import XCTest
@testable import Element

@available (iOS 15.0, *)
final class PillTypeTests: XCTestCase {

    func testUserPill() throws {
        let urls = [
            "https://matrix.to/#/@bob:matrix.org",
            "https://matrix.to/#/user/@bob:matrix.org"
        ]

        for url in urls {
            switch PillType.from(url: URL(string: url)!) {
            case .user(let userId):
                XCTAssertEqual(userId, "@bob:matrix.org")
            default:
                XCTFail("Should be a .user pill")
            }
        }
    }

    func testRoomPill() throws {
        let urls = [
            "https://matrix.to/#/!JppIaYcVkyCiSBVzBn:localhost",
            "https://matrix.to/#/!JppIaYcVkyCiSBVzBn:localhost?via=localhost",
            "https://matrix.to/#/room/!JppIaYcVkyCiSBVzBn:localhost"
        ]
            
        for url in urls {
            switch PillType.from(url: URL(string: url)!) {
            case .room(let roomId):
                XCTAssertEqual(roomId, "!JppIaYcVkyCiSBVzBn:localhost")
            default:
                XCTFail("Should be a .room pill")
            }
        }
    }
    
    func testRoomAlias() throws {
        let urls = [
            "https://matrix.to/#/%23room-alias:localhost",
            "https://matrix.to/#/room/%23room-alias:localhost"
        ]
            
        for url in urls {
            switch PillType.from(url: URL(string: url)!) {
            case .room(let roomId):
                XCTAssertEqual(roomId, "#room-alias:localhost")
            default:
                XCTFail("Should be a .room pill")
            }
        }
    }
    
    func testMessagePill() throws {
        let urls = [
            "https://matrix.to/#/!JppIaYcVkyCiSBVzBn:localhost/$4uvJnQsShl_2OqfqO4dkmUq-mKula7HUx-ictOTPmPc",
            "https://matrix.to/#/!JppIaYcVkyCiSBVzBn:localhost/$4uvJnQsShl_2OqfqO4dkmUq-mKula7HUx-ictOTPmPc?via=localhost"
        ]
            
        for url in urls {
            switch PillType.from(url: URL(string: url)!) {
            case .message(let roomId, let eventId):
                XCTAssertEqual(roomId, "!JppIaYcVkyCiSBVzBn:localhost")
                XCTAssertEqual(eventId, "$4uvJnQsShl_2OqfqO4dkmUq-mKula7HUx-ictOTPmPc")
            default:
                XCTFail("Should be a .message pill")
            }
        }
    }
    
    func testMessagePillWithRoomAlias() throws {
        let urls = [
            "https://matrix.to/#/%23room-alias:localhost/$4uvJnQsShl_2OqfqO4dkmUq-mKula7HUx-ictOTPmPc?via=localhost"
        ]
            
        for url in urls {
            switch PillType.from(url: URL(string: url)!) {
            case .message(let roomId, let eventId):
                XCTAssertEqual(roomId, "#room-alias:localhost")
                XCTAssertEqual(eventId, "$4uvJnQsShl_2OqfqO4dkmUq-mKula7HUx-ictOTPmPc")
            default:
                XCTFail("Should be a .message pill")
            }
        }
    }
    
    func testNotAPermalink() throws {
        XCTAssertNil(PillType.from(url: URL(string: "matrix.org")!))
    }

}
