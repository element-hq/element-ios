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

import SwiftUI
import Combine

typealias TemplateRoomChatViewModelType = StateStoreViewModel<TemplateRoomChatViewState,
                                                              Never,
                                                              TemplateRoomChatViewAction>

class TemplateRoomChatViewModel: TemplateRoomChatViewModelType, TemplateRoomChatViewModelProtocol {
    
    enum Constants {
        static let maxTimeBeforeNewBubble: TimeInterval = 5*60
    }
    // MARK: - Properties
    
    // MARK: Private
    
    private let templateRoomChatService: TemplateRoomChatServiceProtocol
    
    // MARK: Public
    
    var callback: ((TemplateRoomChatViewModelAction) -> Void)?
    
    // MARK: - Setup
    
    init(templateRoomChatService: TemplateRoomChatServiceProtocol) {
        self.templateRoomChatService = templateRoomChatService
        super.init(initialViewState: Self.defaultState(templateRoomChatService: templateRoomChatService))
        setupMessageObserving()
        setupRoomInitializationObserving()
    }
    
    private func setupRoomInitializationObserving() {
        templateRoomChatService
            .roomInitializationStatus
            .sink { [weak self] status in
                self?.state.roomInitializationStatus = status
            }
            .store(in: &cancellables)
    }
    
    private func setupMessageObserving() {
        templateRoomChatService
            .chatMessagesSubject
            .map(Self.makeBubbles(messages:))
            .sink { [weak self] bubbles in
                self?.state.bubbles = bubbles
            }
            .store(in: &cancellables)
    }
    
    private static func defaultState(templateRoomChatService: TemplateRoomChatServiceProtocol) -> TemplateRoomChatViewState {
        let bindings = TemplateRoomChatViewModelBindings(messageInput: "")
        return TemplateRoomChatViewState(roomInitializationStatus: .notInitialized, roomName: templateRoomChatService.roomName, bubbles: [], bindings: bindings)
    }
    
    private static func makeBubbles(messages: [TemplateRoomChatMessage]) -> [TemplateRoomChatBubble] {
        
        var bubbleOrder = [String]()
        var bubbleMap = [String:TemplateRoomChatBubble]()
        
        messages.enumerated().forEach { i, message in
            // New message content
            let messageItem = TemplateRoomChatBubbleItem(
                id: message.id,
                timestamp: message.timestamp,
                content: .message(message.content)
            )
            if i > 0,
               let lastBubbleId = bubbleOrder.last,
               var lastBubble = bubbleMap[lastBubbleId],
               lastBubble.sender.id == message.sender.id,
               let interveningTime =  lastBubble.items.last?.timestamp.timeIntervalSince(message.timestamp),
               abs(interveningTime) < Constants.maxTimeBeforeNewBubble
            {
                // if the last bubble's last message was within
                // the last 5 minutes append
                let item = TemplateRoomChatBubbleItem(
                    id: message.id,
                    timestamp: message.timestamp,
                    content: .message(message.content)
                )
                lastBubble.items.append(item)
                bubbleMap[lastBubble.id] = lastBubble
            } else {
                // else create a new bubble and add the message as the first item
                let bubble = TemplateRoomChatBubble(
                    id: message.id,
                    sender: message.sender,
                    items: [messageItem]
                )
                bubbleOrder.append(bubble.id)
                bubbleMap[bubble.id] = bubble
            }
        }
        return bubbleOrder.compactMap({ bubbleMap[$0] })
    }
    
    // MARK: - Public
    
    override func process(viewAction: TemplateRoomChatViewAction) {
        switch viewAction {
        case .done:
            callback?(.done)
        case .sendMessage:
            templateRoomChatService.send(textMessage: state.bindings.messageInput)
            state.bindings.messageInput = ""
        }
    }
}
