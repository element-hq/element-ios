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

import Foundation
import Combine

@available(iOS 14.0, *)
class MockTemplateRoomChatService: TemplateRoomChatServiceProtocol {
    
    let roomName: String? = "New Vector"
    
    static let amadine = TemplateRoomChatMember(id: "@amadine:matrix.org", avatarUrl: "!aaabaa:matrix.org", displayName: "Amadine")
    static let mathew = TemplateRoomChatMember(id: "@mathew:matrix.org", avatarUrl: "!bbabb:matrix.org", displayName: "Mathew")
    static let mockMessages = [
        TemplateRoomChatMessage(id: "!0:matrix.org", body: "Shall I put it live?", sender: amadine, timestamp: Date(timeIntervalSinceNow: 60 * -3)),
        TemplateRoomChatMessage(id: "!1:matrix.org", body: "Yea go for it! ...and then let's head to the pub", sender: mathew, timestamp: Date(timeIntervalSinceNow: 60)),
        TemplateRoomChatMessage(id: "!2:matrix.org", body: "Deal.", sender: amadine, timestamp: Date(timeIntervalSinceNow: 60 * -2)),
        TemplateRoomChatMessage(id: "!3:matrix.org", body: "Ok, Done. 🍻", sender: amadine, timestamp: Date(timeIntervalSinceNow: 60 * -1)),
    ]
    var chatMessagesSubject: CurrentValueSubject<[TemplateRoomChatMessage], Never>

    init(messages: [TemplateRoomChatMessage] = mockMessages) {
        chatMessagesSubject = CurrentValueSubject(messages)
    }
    
    func send(message: String) {
        let newMessage = TemplateRoomChatMessage(id: "!\(chatMessagesSubject.value.count):matrix.org", body: message, sender: Self.amadine, timestamp: Date())
        self.chatMessagesSubject.value += [newMessage]
    }
    
    func simulateUpdate(messages: [TemplateRoomChatMessage]) {
        self.chatMessagesSubject.send(messages)
    }
}
