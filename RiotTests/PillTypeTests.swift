// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
