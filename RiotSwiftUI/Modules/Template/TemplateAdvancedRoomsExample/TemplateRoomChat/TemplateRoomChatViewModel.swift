//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias TemplateRoomChatViewModelType = StateStoreViewModel<TemplateRoomChatViewState, TemplateRoomChatViewAction>

class TemplateRoomChatViewModel: TemplateRoomChatViewModelType, TemplateRoomChatViewModelProtocol {
    enum Constants {
        static let maxTimeBeforeNewBubble: TimeInterval = 5 * 60
    }
    
    private let templateRoomChatService: TemplateRoomChatServiceProtocol
    
    var callback: ((TemplateRoomChatViewModelAction) -> Void)?
    
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
        var bubbleMap = [String: TemplateRoomChatBubble]()
        
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
               let interveningTime = lastBubble.items.last?.timestamp.timeIntervalSince(message.timestamp),
               abs(interveningTime) < Constants.maxTimeBeforeNewBubble {
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
        return bubbleOrder.compactMap { bubbleMap[$0] }
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
