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

@available(iOS 14, *)
typealias MessageContextMenuViewModelType = StateStoreViewModel<MessageContextMenuViewState,
                                                                 MessageContextMenuViewAction>
@available(iOS 14, *)
class MessageContextMenuViewModel: MessageContextMenuViewModelType, MessageContextMenuViewModelProtocol {

    // MARK: - Properties

    // MARK: Private

    private let service: MessageContextMenuServiceProtocol

    // MARK: Public

    var completion: ((MessageContextMenuViewModelResult) -> Void)?

    // MARK: - Setup

    static func makeMessageContextMenuViewModel(service: MessageContextMenuServiceProtocol) -> MessageContextMenuViewModelProtocol {
        return MessageContextMenuViewModel(service: service)
    }

    private init(service: MessageContextMenuServiceProtocol) {
        self.service = service
        super.init(initialViewState: Self.defaultState(service: service))
    }

    private static func defaultState(service: MessageContextMenuServiceProtocol) -> MessageContextMenuViewState {
        return MessageContextMenuViewState(
            menu: service.menuSubject.value,
            previewImage: service.previewImageSubject.value,
            intialFrame: service.initialFrameSubject.value,
            reactions: service.reactionSubject.value
        )
    }
    
    // MARK: - Public

    override func process(viewAction: MessageContextMenuViewAction) {
        switch viewAction {
        case .cancel:
            completion?(.cancel)
        case .menuItemPressed(let item):
            completion?(.done(item.type))
        case .reactionItemPressed(let item):
            completion?(.updateReaction(item.emoji, !item.isSelected))
        case .moreReactionsItemPressed:
            completion?(.moreReactions)
        }
    }
}
