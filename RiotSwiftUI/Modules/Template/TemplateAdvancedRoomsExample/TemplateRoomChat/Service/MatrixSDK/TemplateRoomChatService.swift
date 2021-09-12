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
class TemplateRoomChatService: TemplateRoomChatServiceProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let room: MXRoom
    private let eventFormatter: EventFormatter
    private var listenerReference: Any?
    
    // MARK: Public
    private(set) var chatMessagesSubject: CurrentValueSubject<[TemplateRoomChatMessage], Never>
    
    // MARK: - Setup
    
    init(room: MXRoom) {
        self.room = room
        self.eventFormatter = EventFormatter(matrixSession: room.mxSession)
        let batch = room.enumeratorForStoredMessages.nextEventsBatch(50)
        let messageBatch = chatMessages(from: batch ?? [])
        chatMessagesSubject = CurrentValueSubject(messageBatch)
    }
    
    
    func senderForMessage(event: MXEvent) -> TemplateRoomChatMember? {
        guard let sender = event.sender else {
            return nil
        }
        let displayName = eventFormatter.senderDisplayName(for: event, with: room.dangerousSyncState)
        let avatarUrl = eventFormatter.senderAvatarUrl(for: event, with: room.dangerousSyncState)
        return TemplateRoomChatMember(id: sender, avatarUrl: avatarUrl, displayName: displayName)
    }
    
    private func chatMessages(from events: [MXEvent]) -> [TemplateRoomChatMessage] {
        
        eve
        return events
            .filter({ event in
            event.type == kMXEventTypeStringRoomMessage
                && event.content["msgtype"] as? String == kMXMessageTypeText
            })
            .compactMap({ event -> TemplateRoomChatMessage?  in
                guard let eventId = event.eventId,
                      let eventBody = event.content["body"] as? String,
                      let sender = senderForMessage(event: event)
                      else { return nil }
                return TemplateRoomChatMessage(id: eventId,
                                        body: eventBody,
                                        sender: sender)
            })
    }


    deinit {
//        guard let reference = listenerReference else { return }
    }

}
