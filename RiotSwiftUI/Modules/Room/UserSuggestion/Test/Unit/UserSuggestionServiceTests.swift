//
// Copyright 2021 New Vector Ltd
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

import Combine
import XCTest

@testable import RiotSwiftUI

class UserSuggestionServiceTests: XCTestCase {
    var service: UserSuggestionService!
    var canMentionRoom = false
    
    override func setUp() {
        service = UserSuggestionService(roomMemberProvider: self, shouldDebounce: false)
        canMentionRoom = false
    }
    
    func testAlice() {
        service.processTextMessage("@Al")
        XCTAssertEqual(service.items.value.first?.displayName, "Alice")
        
        service.processTextMessage("@al")
        XCTAssertEqual(service.items.value.first?.displayName, "Alice")
        
        service.processTextMessage("@ice")
        XCTAssertEqual(service.items.value.first?.displayName, "Alice")
        
        service.processTextMessage("@Alice")
        XCTAssertEqual(service.items.value.first?.displayName, "Alice")
        
        service.processTextMessage("@alice:matrix.org")
        XCTAssertEqual(service.items.value.first?.displayName, "Alice")
    }
    
    func testBob() {
        service.processTextMessage("@ob")
        XCTAssertEqual(service.items.value.first?.displayName, "Bob")
        
        service.processTextMessage("@ob:")
        XCTAssertEqual(service.items.value.first?.displayName, "Bob")
        
        service.processTextMessage("@b:matrix")
        XCTAssertEqual(service.items.value.first?.displayName, "Bob")
    }
    
    func testBoth() {
        service.processTextMessage("@:matrix")
        XCTAssertEqual(service.items.value.first?.displayName, "Alice")
        XCTAssertEqual(service.items.value.last?.displayName, "Bob")
        
        service.processTextMessage("@.org")
        XCTAssertEqual(service.items.value.first?.displayName, "Alice")
        XCTAssertEqual(service.items.value.last?.displayName, "Bob")
    }
    
    func testEmptyResult() {
        service.processTextMessage("Lorem ipsum idolor")
        XCTAssertTrue(service.items.value.isEmpty)
        
        service.processTextMessage("@")
        XCTAssertTrue(service.items.value.isEmpty)
        
        service.processTextMessage("@@")
        XCTAssertTrue(service.items.value.isEmpty)
        
        service.processTextMessage("alice@matrix.org")
        XCTAssertTrue(service.items.value.isEmpty)
    }
    
    func testStuff() {
        service.processTextMessage("@@")
        XCTAssertTrue(service.items.value.isEmpty)
    }
    
    func testWhitespaces() {
        service.processTextMessage("")
        XCTAssertTrue(service.items.value.isEmpty)
        
        service.processTextMessage(" ")
        XCTAssertTrue(service.items.value.isEmpty)
        
        service.processTextMessage("\n")
        XCTAssertTrue(service.items.value.isEmpty)
        
        service.processTextMessage(" \n ")
        XCTAssertTrue(service.items.value.isEmpty)
        
        service.processTextMessage("@A   ")
        XCTAssertTrue(service.items.value.isEmpty)
        
        service.processTextMessage("  @A   ")
        XCTAssertTrue(service.items.value.isEmpty)
    }
    
    func testRoomWithoutPower() {
        // Given a user without the power to mention a room.
        canMentionRoom = false
        
        // Given a user without the power to mention a room.
        service.processTextMessage("@ro")
        
        // Then the completion for a room mention should not be shown.
        XCTAssertTrue(service.items.value.isEmpty)
    }
    
    func testRoomWithPower() {
        // Given a user without the power to mention a room.
        canMentionRoom = true
        
        // Given a user without the power to mention a room.
        service.processTextMessage("@ro")
        
        // Then the completion for a room mention should be shown.
        XCTAssertEqual(service.items.value.first?.userId, UserSuggestionID.room)
    }
}

extension UserSuggestionServiceTests: RoomMembersProviderProtocol {
    func fetchMembers(_ members: @escaping ([RoomMembersProviderMember]) -> Void) {
        let users = [("Alice", "@alice:matrix.org"),
                     ("Bob", "@bob:matrix.org")]
        
        members(users.map { user in
            RoomMembersProviderMember(userId: user.1, displayName: user.0, avatarUrl: "")
        })
    }
}
