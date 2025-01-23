//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
