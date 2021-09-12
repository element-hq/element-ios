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
    
@available(iOS 14.0, *)
class TemplateRoomChatViewModel: ObservableObject, TemplateRoomChatViewModelProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    private let templateRoomChatService: TemplateRoomChatServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: Public
    @Published var input: TemplateRoomChatViewModelInput
    @Published private(set) var viewState: TemplateRoomChatViewState
    
    var completion: ((TemplateRoomChatViewModelResult) -> Void)?
    
    // MARK: - Setup
    init(templateRoomChatService: TemplateRoomChatServiceProtocol, initialState: TemplateRoomChatViewState? = nil) {
        self.input = TemplateRoomChatViewModelInput(messageInput: "")
        self.templateRoomChatService = templateRoomChatService
        self.viewState = initialState ?? Self.defaultState(templateRoomChatService: templateRoomChatService)
        
        templateRoomChatService.chatMessagesSubject
            .map(Self.makeBubbles(messages:))
            .map(TemplateRoomChatStateAction.updateBubbles)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] action in
                self?.dispatch(action:action)
            })
            .store(in: &cancellables)
    }
    
    private static func defaultState(templateRoomChatService: TemplateRoomChatServiceProtocol) -> TemplateRoomChatViewState {
        let bubbles = makeBubbles(messages: templateRoomChatService.chatMessagesSubject.value)
        return TemplateRoomChatViewState(bubbles: bubbles)
    }
    
    private static func makeBubbles(messages: [TemplateRoomChatMessage]) -> [TemplateRoomChatBubble] {
        
        
        messages.enumerated().forEach { i, message in
            let currentMessage = messages[i]
            if i > 0 {
                let lastMessage = messages[i-1]
            } else {
                TemplateRoomChatBubble(
                    id: message.,
                    avatar: <#T##AvatarInputProtocol#>,
                    displayName: <#T##String?#>,
                    items: <#T##[TemplateRoomChatBubbleItem]#>
                )
            }
        }
    }
    
    // MARK: - Public
    func process(viewAction: TemplateRoomChatViewAction) {
        switch viewAction {
        case .cancel:
            cancel()
        case .done:
            done()
        }
    }
    
    // MARK: - Private
    /**
     Send state actions to mutate the state.
     */
    private func dispatch(action: TemplateRoomChatStateAction) {
        Self.reducer(state: &self.viewState, action: action)
    }
    
    /**
     A redux style reducer, all modifications to state happen here. Receives a state and a state action and produces a new state.
     */
    private static func reducer(state: inout TemplateRoomChatViewState, action: TemplateRoomChatStateAction) {
        switch action {
        case .updateBubbles(let bubbles):
            state.bubbles = bubbles
        }
        UILog.debug("[TemplateRoomChatViewModel] reducer with action \(action) produced state: \(state)")
    }
    
    private func done() {
        completion?(.done)
    }
    
    private func cancel() {
        completion?(.cancel)
    }
}
