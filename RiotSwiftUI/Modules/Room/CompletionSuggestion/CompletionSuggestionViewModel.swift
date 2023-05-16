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

typealias CompletionSuggestionViewModelType = StateStoreViewModel<CompletionSuggestionViewState, CompletionSuggestionViewAction>

class CompletionSuggestionViewModel: CompletionSuggestionViewModelType, CompletionSuggestionViewModelProtocol {
    // MARK: - Properties
    
    // MARK: Private
    
    private let completionSuggestionService: CompletionSuggestionServiceProtocol
    
    // MARK: Public

    var sharedContext: CompletionSuggestionViewModelType.Context {
        context
    }

    var completion: ((CompletionSuggestionViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init(completionSuggestionService: CompletionSuggestionServiceProtocol) {
        self.completionSuggestionService = completionSuggestionService
        
        let items = completionSuggestionService.items.value.map { suggestionItem in
            switch suggestionItem {
            case .command(let completionSuggestionCommandItem):
                return CompletionSuggestionViewStateItem.command(
                    name: completionSuggestionCommandItem.name,
                    parametersFormat: completionSuggestionCommandItem.parametersFormat,
                    description: completionSuggestionCommandItem.description
                )
            case .user(let completionSuggestionUserItem):
                return CompletionSuggestionViewStateItem.user(id: completionSuggestionUserItem.userId,
                                                              avatar: completionSuggestionUserItem,
                                                              displayName: completionSuggestionUserItem.displayName)
            }
        }
        
        super.init(initialViewState: CompletionSuggestionViewState(items: items))
        
        completionSuggestionService.items.sink { [weak self] items in
            self?.state.items = items.map { item in
                switch item {
                case .command(let completionSuggestionCommandItem):
                    return CompletionSuggestionViewStateItem.command(
                        name: completionSuggestionCommandItem.name,
                        parametersFormat: completionSuggestionCommandItem.parametersFormat,
                        description: completionSuggestionCommandItem.description
                    )
                case .user(let completionSuggestionUserItem):
                    return CompletionSuggestionViewStateItem.user(id: completionSuggestionUserItem.userId,
                                                                  avatar: completionSuggestionUserItem,
                                                                  displayName: completionSuggestionUserItem.displayName)
                }
            }
        }.store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: CompletionSuggestionViewAction) {
        switch viewAction {
        case .selectedItem(let item):
            completion?(.selectedItemWithIdentifier(item.id))
        }
    }
}
