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
import Foundation

class TemplateRoomChatService: TemplateRoomChatServiceProtocol {
    private let room: MXRoom
    private let eventFormatter: EventFormatter
    private var timeline: MXEventTimeline?
    private var eventBatch: [MXEvent]
    private var roomListenerReference: Any?

    private(set) var chatMessagesSubject: CurrentValueSubject<[TemplateRoomChatMessage], Never>
    private(set) var roomInitializationStatus: CurrentValueSubject<TemplateRoomChatRoomInitializationStatus, Never>
    
    var roomName: String? {
        room.summary.displayname
    }
    
    init(room: MXRoom) {
        self.room = room
        eventFormatter = EventFormatter(matrixSession: room.mxSession)
        chatMessagesSubject = CurrentValueSubject([])
        roomInitializationStatus = CurrentValueSubject(.notInitialized)
        eventBatch = [MXEvent]()
        initializeRoom()
    }
    
    deinit {
        guard let reference = roomListenerReference else { return }
        room.removeListener(reference)
    }
    
    // MARK: Public

    func send(textMessage: String) {
        var localEcho: MXEvent?
        room.sendTextMessage(textMessage, threadId: nil, localEcho: &localEcho, completion: { _ in })
    }
    
    // MARK: Private
    
    private func initializeRoom() {
        room.liveTimeline { [weak self] timeline in
            guard let self = self,
                  let timeline = timeline
            else {
                return
            }
            self.timeline = timeline
            timeline.resetPagination()
            self.roomListenerReference = timeline.listenToEvents([.roomMessage]) { [weak self] event, direction, _ in
                guard let self = self else { return }
                if direction == .backwards {
                    self.eventBatch.append(event)
                } else {
                    self.chatMessagesSubject.value += self.mapChatMessages(from: [event])
                }
            }
            timeline.paginate(200, direction: .backwards, onlyFromStore: false) { result in
                guard result.isSuccess else {
                    self.roomInitializationStatus.value = .failedToInitialize
                    return
                }
                let sortedBatch = self.eventBatch.sorted(by: { $0.originServerTs < $1.originServerTs })
                self.chatMessagesSubject.value = self.mapChatMessages(from: sortedBatch)
                self.roomInitializationStatus.value = .initialized
            }
        }
    }
    
    private func mapChatMessages(from events: [MXEvent]) -> [TemplateRoomChatMessage] {
        events
            .filter { event in
                event.type == kMXEventTypeStringRoomMessage
                    && event.content[kMXMessageTypeKey] as? String == kMXMessageTypeText
                
                // TODO: New to our SwiftUI Template? Why not implement another message type like image?
            }
            .compactMap { event -> TemplateRoomChatMessage? in
                guard let eventId = event.eventId,
                      let body = event.content[kMXMessageBodyKey] as? String,
                      let sender = senderForMessage(event: event)
                else { return nil }
                
                return TemplateRoomChatMessage(
                    id: eventId,
                    content: .text(TemplateRoomChatMessageTextContent(body: body)),
                    sender: sender,
                    timestamp: Date(timeIntervalSince1970: TimeInterval(event.originServerTs / 1000))
                )
            }
    }
    
    private func senderForMessage(event: MXEvent) -> TemplateRoomChatMember? {
        guard let sender = event.sender, let roomState = timeline?.state else {
            return nil
        }
        let displayName = eventFormatter.senderDisplayName(for: event, with: roomState)
        let avatarUrl = eventFormatter.senderAvatarUrl(for: event, with: roomState)
        return TemplateRoomChatMember(id: sender, avatarUrl: avatarUrl, displayName: displayName)
    }
}
