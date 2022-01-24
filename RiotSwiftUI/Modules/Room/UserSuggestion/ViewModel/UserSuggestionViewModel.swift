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
typealias UserSuggestionViewModelType = StateStoreViewModel <UserSuggestionViewState,
                                                             UserSuggestionStateAction,
                                                             UserSuggestionViewAction>
@available(iOS 14, *)
class UserSuggestionViewModel: UserSuggestionViewModelType, UserSuggestionViewModelProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let userSuggestionService: UserSuggestionServiceProtocol
    
    // MARK: Public
    
    var completion: ((UserSuggestionViewModelResult) -> Void)?
    
    // MARK: - Setup

    static func makeUserSuggestionViewModel(userSuggestionService: UserSuggestionServiceProtocol) -> UserSuggestionViewModelProtocol {
        return UserSuggestionViewModel(userSuggestionService: userSuggestionService)
    }
    
    private init(userSuggestionService: UserSuggestionServiceProtocol) {
        self.userSuggestionService = userSuggestionService
        super.init(initialViewState: Self.defaultState(userSuggestionService: userSuggestionService))
        setupItemsObserving()
    }
    
    private func setupItemsObserving() {
        let updatePublisher = userSuggestionService.items
            .map(UserSuggestionStateAction.updateWithItems)
            .eraseToAnyPublisher()
        dispatch(actionPublisher: updatePublisher)
    }
    
    private static func defaultState(userSuggestionService: UserSuggestionServiceProtocol) -> UserSuggestionViewState {
        let viewStateItems = userSuggestionService.items.value.map { suggestionItem in
            return UserSuggestionViewStateItem(id: suggestionItem.userId, avatar: suggestionItem, displayName: suggestionItem.displayName)
        }
        
        return UserSuggestionViewState(items: viewStateItems)
    }
    
    // MARK: - Public
    
    override func process(viewAction: UserSuggestionViewAction) {
        switch viewAction {
        case .selectedItem(let item):
            completion?(.selectedItemWithIdentifier(item.id))
        }
    }
    
    override class func reducer(state: inout UserSuggestionViewState, action: UserSuggestionStateAction) {
        switch action {
        case .updateWithItems(let items):
            state.items = items.map({ item in
                UserSuggestionViewStateItem(id: item.userId, avatar: item, displayName: item.displayName)
            })
        }
    }
}
