//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

class MockTemplateRoomChatService: TemplateRoomChatServiceProtocol {
    let roomName: String? = "New Vector"
    
    static let amadine = TemplateRoomChatMember(id: "@amadine:matrix.org", avatarUrl: "!aaabaa:matrix.org", displayName: "Amadine")
    static let mathew = TemplateRoomChatMember(id: "@mathew:matrix.org", avatarUrl: "!bbabb:matrix.org", displayName: "Mathew")
    static let mockMessages = [
        TemplateRoomChatMessage(id: "!0:matrix.org", content: .text(TemplateRoomChatMessageTextContent(body: "Shall I put it live?")), sender: amadine, timestamp: Date(timeIntervalSinceNow: 60 * -3)),
        TemplateRoomChatMessage(id: "!1:matrix.org", content: .text(TemplateRoomChatMessageTextContent(body: "Yea go for it! ...and then let's head to the pub")), sender: mathew, timestamp: Date(timeIntervalSinceNow: 60)),
        TemplateRoomChatMessage(id: "!2:matrix.org", content: .text(TemplateRoomChatMessageTextContent(body: "Deal.")), sender: amadine, timestamp: Date(timeIntervalSinceNow: 60 * -2)),
        TemplateRoomChatMessage(id: "!3:matrix.org", content: .text(TemplateRoomChatMessageTextContent(body: "Ok, Done. 🍻")), sender: amadine, timestamp: Date(timeIntervalSinceNow: 60 * -1))
    ]
    var roomInitializationStatus: CurrentValueSubject<TemplateRoomChatRoomInitializationStatus, Never>
    var chatMessagesSubject: CurrentValueSubject<[TemplateRoomChatMessage], Never>

    init(messages: [TemplateRoomChatMessage] = mockMessages) {
        roomInitializationStatus = CurrentValueSubject(.notInitialized)
        chatMessagesSubject = CurrentValueSubject(messages)
    }
    
    func send(textMessage: String) {
        let newMessage = TemplateRoomChatMessage(id: "!\(chatMessagesSubject.value.count):matrix.org", content: .text(TemplateRoomChatMessageTextContent(body: textMessage)), sender: Self.amadine, timestamp: Date())
        chatMessagesSubject.value += [newMessage]
    }
    
    func simulateUpdate(initializationStatus: TemplateRoomChatRoomInitializationStatus) {
        roomInitializationStatus.value = initializationStatus
    }
    
    func simulateUpdate(messages: [TemplateRoomChatMessage]) {
        chatMessagesSubject.value = messages
    }
}
