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
import SwiftUI

typealias UserSuggestionViewModelType = StateStoreViewModel<UserSuggestionViewState, UserSuggestionViewAction>

class UserSuggestionViewModel: UserSuggestionViewModelType, UserSuggestionViewModelProtocol {
    // MARK: - Properties
    
    // MARK: Private
    
    private let userSuggestionService: UserSuggestionServiceProtocol
    
    // MARK: Public
    
    var completion: ((UserSuggestionViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init(userSuggestionService: UserSuggestionServiceProtocol) {
        self.userSuggestionService = userSuggestionService
        
        let items = userSuggestionService.items.value.map { suggestionItem in
            UserSuggestionViewStateItem(id: suggestionItem.userId, avatar: suggestionItem, displayName: suggestionItem.displayName)
        }
        
        super.init(initialViewState: UserSuggestionViewState(items: items))
        
        userSuggestionService.items.sink { [weak self] items in
            self?.state.items = items.map { item in
                UserSuggestionViewStateItem(id: item.userId, avatar: item, displayName: item.displayName)
            }
        }.store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: UserSuggestionViewAction) {
        switch viewAction {
        case .selectedItem(let item):
            completion?(.selectedItemWithIdentifier(item.id))
        }
    }
}
