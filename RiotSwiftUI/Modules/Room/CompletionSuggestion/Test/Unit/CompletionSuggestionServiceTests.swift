//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

@testable import RiotSwiftUI

class CompletionSuggestionServiceTests: XCTestCase {
    var service: CompletionSuggestionService!
    var canMentionRoom = false
    var isRoomAdmin = false
    
    override func setUp() {
        service = CompletionSuggestionService(roomMemberProvider: self,
                                              commandProvider: self,
                                              shouldDebounce: false)
        canMentionRoom = false
        isRoomAdmin = false
    }

    // MARK: - User suggestions

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

    // MARK: - Command suggestions

    func testJoin() {
        service.processTextMessage("/jo")
        XCTAssertEqual(service.items.value.first?.asCommand?.name, "/join")

        service.processTextMessage("/joi")
        XCTAssertEqual(service.items.value.first?.asCommand?.name, "/join")

        service.processTextMessage("/join")
        XCTAssertEqual(service.items.value.first?.asCommand?.name, "/join")

        service.processTextMessage("/oin")
        XCTAssertEqual(service.items.value.first?.asCommand?.name, "/join")
    }

    func testInvite() {
        service.processTextMessage("/inv")
        XCTAssertEqual(service.items.value.first?.asCommand?.name, "/invite")

        service.processTextMessage("/invite")
        XCTAssertEqual(service.items.value.first?.asCommand?.name, "/invite")

        service.processTextMessage("/vite")
        XCTAssertEqual(service.items.value.first?.asCommand?.name, "/invite")
    }

    func testMultipleResults() {
        service.processTextMessage("/in")
        XCTAssertEqual(
            service.items.value.compactMap { $0.asCommand?.name },
            ["/invite", "/join"]
        )
    }

    func testDoubleSlashDontTrigger() {
        service.processTextMessage("//")
        XCTAssertTrue(service.items.value.isEmpty)
    }

    func testNonLeadingSlashCommandDontTrigger() {
        service.processTextMessage("test /joi")
        XCTAssertTrue(service.items.value.isEmpty)
    }

    func testAdminCommandsAreNotAvailable() {
        isRoomAdmin = false

        service.processTextMessage("/op")
        XCTAssertTrue(service.items.value.isEmpty)
    }

    func testAdminCommandsAreAvailable() {
        isRoomAdmin = true

        service.processTextMessage("/op")
        XCTAssertEqual(service.items.value.compactMap { $0.asCommand?.name }, ["/op", "/deop"])
    }

    func testDisplayAllCommandsAsStandardUser() {
        isRoomAdmin = false

        service.processTextMessage("/")
        XCTAssertEqual(
            service.items.value.compactMap { $0.asCommand?.name },
            ["/ban", "/invite", "/join", "/me"]
        )
    }

    func testDisplayAllCommandsAsAdmin() {
        isRoomAdmin = true

        service.processTextMessage("/")
        XCTAssertEqual(
            service.items.value.compactMap { $0.asCommand?.name },
            ["/ban", "/invite", "/join", "/op", "/deop", "/me"]
        )
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
                                    description: "Bans user with given id",
                                    requiresAdminPowerLevel: false),
            CommandsProviderCommand(name: "/invite",
                                    parametersFormat: "<user-id>",
                                    description: "Invites user with given id to current room",
                                    requiresAdminPowerLevel: false),
            CommandsProviderCommand(name: "/join",
                                    parametersFormat: "<room-address>",
                                    description: "Joins room with given address",
                                    requiresAdminPowerLevel: false),
            CommandsProviderCommand(name: "/op",
                                    parametersFormat: "<user-id> <power-level>",
                                    description: "Define the power level of a user",
                                    requiresAdminPowerLevel: true),
            CommandsProviderCommand(name: "/deop",
                                    parametersFormat: "<user-id>",
                                    description: "Deops user with given id",
                                    requiresAdminPowerLevel: true),
            CommandsProviderCommand(name: "/me",
                                    parametersFormat: "<message>",
                                    description: "Displays action",
                                    requiresAdminPowerLevel: false)
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
