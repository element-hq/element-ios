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

class CompletionSuggestionServiceTests: XCTestCase {
    var service: CompletionSuggestionService!
    var canMentionRoom = false
    
    override func setUp() {
        service = CompletionSuggestionService(roomMemberProvider: self,
                                              commandProvider: self,
                                              shouldDebounce: false)
        canMentionRoom = false
    }
    
    func testAlice() {
        service.processTextMessage("@Al")
        XCTAssertEqual(service.items.value.first?.asUser?.displayName, "Alice")
        
        service.processTextMessage("@al")
        XCTAssertEqual(service.items.value.first?.asUser?.displayName, "Alice")
        
        service.processTextMessage("@ice")
        XCTAssertEqual(service.items.value.first?.asUser?.displayName, "Alice")
        
        service.processTextMessage("@Alice")
        XCTAssertEqual(service.items.value.first?.asUser?.displayName, "Alice")
        
        service.processTextMessage("@alice:matrix.org")
        XCTAssertEqual(service.items.value.first?.asUser?.displayName, "Alice")
    }
    
    func testBob() {
        service.processTextMessage("@ob")
        XCTAssertEqual(service.items.value.first?.asUser?.displayName, "Bob")
        
        service.processTextMessage("@ob:")
        XCTAssertEqual(service.items.value.first?.asUser?.displayName, "Bob")
        
        service.processTextMessage("@b:matrix")
        XCTAssertEqual(service.items.value.first?.asUser?.displayName, "Bob")
    }
    
    func testBoth() {
        service.processTextMessage("@:matrix")
        XCTAssertEqual(service.items.value.first?.asUser?.displayName, "Alice")
        XCTAssertEqual(service.items.value.last?.asUser?.displayName, "Bob")
        
        service.processTextMessage("@.org")
        XCTAssertEqual(service.items.value.first?.asUser?.displayName, "Alice")
        XCTAssertEqual(service.items.value.last?.asUser?.displayName, "Bob")
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
        // Given a user with the power to mention a room.
        canMentionRoom = true
        
        // Given a user with the power to mention a room.
        service.processTextMessage("@ro")
        
        // Then the completion for a room mention should be shown.
        XCTAssertEqual(service.items.value.first?.asUser?.userId, CompletionSuggestionUserID.room)
    }
}

extension CompletionSuggestionServiceTests: RoomMembersProviderProtocol {
    func fetchMembers(_ members: @escaping ([RoomMembersProviderMember]) -> Void) {
        let users = [("Alice", "@alice:matrix.org"),
                     ("Bob", "@bob:matrix.org")]
        
        members(users.map { user in
            RoomMembersProviderMember(userId: user.1, displayName: user.0, avatarUrl: "")
        })
    }
}

extension CompletionSuggestionServiceTests: CommandsProviderProtocol {
    func fetchCommands(_ commands: @escaping ([CommandsProviderCommand]) -> Void) {
        commands([
            CommandsProviderCommand(name: "/ban",
                                    parametersFormat: "<user-id> [<reason>]",
                                    description: "Bans user with given id"),
            CommandsProviderCommand(name: "/invite",
                                    parametersFormat: "<user-id>",
                                    description: "Invites user with given id to current room"),
            CommandsProviderCommand(name: "/join",
                                    parametersFormat: "<room-address>",
                                    description: "Joins room with given address"),
            CommandsProviderCommand(name: "/me",
                                    parametersFormat: "<message>",
                                    description: "Displays action")
        ])
    }
}

extension CompletionSuggestionItem {
    var asUser: CompletionSuggestionUserItemProtocol? {
        if case let .user(value) = self { return value } else { return nil }
    }

    var asCommand: CompletionSuggestionCommandItemProtocol? {
        if case let .command(value) = self { return value } else { return nil }
    }
}
