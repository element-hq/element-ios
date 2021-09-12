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
    
    static let mockMessages = [
        TemplateRoomChatMessage(id: "!aaabaa:matrix.org", body: "Shall I put it live?", sender: "@alice:matrix.org"),
        TemplateRoomChatMessage(id: "!bbbabb:matrix.org", body: "Yea go for it! ...and then let's head to the pub", sender: "@patrice:matrix.org"),
        TemplateRoomChatMessage(id: "!aaabaa:matrix.org", body: "Deal.", sender: "@alice:matrix.org"),
        TemplateRoomChatMessage(id: "!aaabaa:matrix.org", body: "Ok, Done. 🍻", sender: "@alice:matrix.org"),
    ]
    var chatMessagesSubject: CurrentValueSubject<[TemplateRoomChatMessage], Never>

    init(messages: [TemplateRoomChatMessage] = mockMessages) {
        chatMessagesSubject = CurrentValueSubject(messages)
    }
    
    func simulateUpdate(messages: [TemplateRoomChatMessage]) {
        self.chatMessagesSubject.send(messages)
    }
}
