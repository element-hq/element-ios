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
    static let alice = TemplateRoomChatMember(id: "@alice:matrix.org", avatarUrl: "!aaabaa:matrix.org", displayName: "Alice")
    static let mathew = TemplateRoomChatMember(id: "@mathew:matrix.org", avatarUrl: "!bbabb:matrix.org", displayName: "Mathew")
    static let mockMessages = [
        TemplateRoomChatMessage(id: "!11111:matrix.org", body: "Shall I put it live?", sender: alice),
        TemplateRoomChatMessage(id: "!22222:matrix.org", body: "Yea go for it! ...and then let's head to the pub", sender: mathew),
        TemplateRoomChatMessage(id: "!33333:matrix.org", body: "Deal.", sender: alice),
        TemplateRoomChatMessage(id: "!44444:matrix.org", body: "Ok, Done. 🍻", sender: alice),
    ]
    var chatMessagesSubject: CurrentValueSubject<[TemplateRoomChatMessage], Never>

    init(messages: [TemplateRoomChatMessage] = mockMessages) {
        chatMessagesSubject = CurrentValueSubject(messages)
    }
    
    func simulateUpdate(messages: [TemplateRoomChatMessage]) {
        self.chatMessagesSubject.send(messages)
    }
}
